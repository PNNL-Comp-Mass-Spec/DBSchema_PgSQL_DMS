--
-- Name: get_current_manager_activity(boolean, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_current_manager_activity(_activeonly boolean DEFAULT true, _startdate timestamp without time zone DEFAULT NULL::timestamp without time zone, _months integer DEFAULT 3) RETURNS TABLE(source public.citext, who public.citext, what public.citext, status_date timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get snapshot of current manager activity
**
**  Arguments:
**    _activeOnly       When true, only show processors actively running a capture task job or analysis job
**                      When false, use _startDate and _months to show all processors that were active within a date range
**    _startDate        Start date to look for processors that ran at least one capture task job or analysis job; ignored if _activeOnly is true
**                      If null, will auto-compute using the current time and _months
**    _months           Number of months to examine, starting with _startDate; ignored if _activeOnly is true
**
**  Example usage:
**    SELECT * FROM get_current_manager_activity(_activeOnly => true)
**    SELECT * FROM get_current_manager_activity(_activeOnly => false, _startDate => '2022-07-01');
**    SELECT * FROM get_current_manager_activity(_activeOnly => false, _startDate => '2022-07-01', _months => 1);
**
**  Auth:   grk
**  Date:   10/06/2003 grk - Initial version
**          06/01/2004 grk - Fixed initial population of XT with jobs
**          06/23/2004 grk - Used start instead of finish in default population
**          11/04/2004 grk - Widened 'Who' column of XT to match data in some item queries
**          02/24/2004 grk - Fixed problem with null value for assigned_processor_name
**          02/09/2007 grk - Added column to note that activity is stale (Ticket #377)
**          02/27/2007 grk - Fixed prep manager reporting (Ticket #398)
**          04/04/2008 dac - Changed output sort order to DESC
**          09/30/2009 grk - Eliminated references to health log
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          10/27/2022 mem - Change # column to lowercase
**          11/02/2022 mem - Remove # from column name
**          11/16/2022 mem - Ported to PostgreSQL
**          11/17/2022 mem - Updated to use tables in the capture and pipeline schemas ('cap' and 'sw')
**          05/30/2023 mem - Use new step tool column name
**                         - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _endDate timestamp;
BEGIN
    _activeOnly := Coalesce(_activeOnly, true);

    _months := Coalesce(_months, 3);
    If (_months < 1) Then
        _months := 1;
    End If;

    _startDate := Coalesce(_startDate, CURRENT_TIMESTAMP - make_interval(months => _months));

    _endDate = _startDate + make_interval(months => _months);

    -- Temporary table to hold manager status
    --
    CREATE TEMP TABLE Tmp_ManagerActivity (
        Source citext,
        Status_Date timestamp,
        Who  citext,
        What citext
    );

    -- RAISE INFO 'Examining capture tasks and analysis jobs started betwen % and %', _startDate::date, _endDate::date;

    If _activeOnly Then
        INSERT INTO Tmp_ManagerActivity(Who, What, Status_Date, Source)
        SELECT RankQ.Who,
               RankQ.What,
               RankQ.Start,
               'Analysis Jobs' AS Source
        FROM ( SELECT format('Analysis: %s', Processor) AS Who,
                      format('Processing job %s, step %s, tool %s', job, step, tool) AS What,
                      Start,
                      Row_Number() OVER (Partition BY Processor ORDER BY Start DESC) AS StartRank
               FROM sw.t_job_steps
               WHERE State = 4
             ) RankQ
        WHERE RankQ.StartRank = 1;

        INSERT INTO Tmp_ManagerActivity(Who, What, Status_Date, Source)
        SELECT RankQ.Who,
               RankQ.What,
               RankQ.Start,
               'Capture Tasks' AS Source
        FROM ( SELECT format('Capture: %s', Processor) AS Who,
                      format('Processing task %s, step %s, tool %s', job, step, tool) AS What,
                      Start,
                      Row_Number() OVER (Partition BY Processor ORDER BY Start DESC) AS StartRank
               FROM sw.t_job_steps
               WHERE State = 4
             ) RankQ
        WHERE RankQ.StartRank = 1;

        RETURN QUERY
        SELECT
            A.Source,
            A.Who,
            A.What,
            A.Status_Date
        FROM Tmp_ManagerActivity A
        ORDER BY A.Who;

        DROP TABLE Tmp_ManagerActivity;
        RETURN;
    End If;

    -- Populate temporary table with analysis managers that started a job within the date range
    --
    INSERT INTO Tmp_ManagerActivity(Who, What, Status_Date, Source)
    SELECT format('Analysis: %s', M.processor) AS Who,
           'Idle' AS What,
           M.Most_Recent_Start,
           'Analysis Jobs' AS Source
    FROM (  -- Get distinct list of analysis managers
            -- that have been active within the date range
            --
            SELECT UnionQ.processor, Max(Most_Recent_Start) AS Most_Recent_Start
            FROM ( SELECT processor, Max(Coalesce(Start, make_date(1970, 1, 1))) AS Most_Recent_Start
                   FROM sw.t_job_steps
                   WHERE Start BETWEEN _startDate AND _endDate
                   GROUP BY processor
                   UNION
                   SELECT processor, Max(Coalesce(Start, make_date(1970, 1, 1))) AS Most_Recent_Start
                   FROM sw.t_job_steps_history
                   WHERE Start BETWEEN _startDate AND _endDate
                   GROUP BY processor
                ) UnionQ
            GROUP BY UnionQ.processor
        ) M;

    -- Update actively running processors
    --
    UPDATE Tmp_ManagerActivity M
    SET Who = T.Who,
        What = T.What,
        Status_Date = T.Start
    FROM ( SELECT RankQ.Who,
                  RankQ.What,
                  RankQ.Start
           FROM ( SELECT format('Analysis: %s', Processor) AS Who,
                         format('Processing job %s, step %s, tool %s', job, step, tool) AS What,
                         Start,
                         Row_Number() OVER (Partition BY Processor ORDER BY Start DESC) AS StartRank
                  FROM sw.t_job_steps
                  WHERE State = 4 And Start BETWEEN _startDate AND _endDate
                ) RankQ
           WHERE RankQ.StartRank = 1
         ) T
    WHERE M.Who = T.Who;


    -- Populate temporary table with capture task managers that started a capture or archive task within the date range
    --
    INSERT INTO Tmp_ManagerActivity(Who, What, Status_Date, Source)
    SELECT format('Capture: %s', M.processor) AS Who,
           'Idle' AS What,
           M.Most_Recent_Start,
           'Capture Tasks' AS Source
    FROM (  -- Get distinct list of analysis managers
            -- that have been active within the date range
            --
            SELECT UnionQ.processor, Max(Most_Recent_Start) AS Most_Recent_Start
            FROM ( SELECT processor, Max(Coalesce(Start, make_date(1970, 1, 1))) AS Most_Recent_Start
                   FROM cap.t_task_steps
                   WHERE Start BETWEEN _startDate AND _endDate
                   GROUP BY processor
                   UNION
                   SELECT processor, Max(Coalesce(Start, make_date(1970, 1, 1))) AS Most_Recent_Start
                   FROM cap.t_task_steps_history
                   WHERE Start BETWEEN _startDate AND _endDate
                   GROUP BY processor
                ) UnionQ
            GROUP BY UnionQ.processor
        ) M;

    -- Update actively running processors
    --
    UPDATE Tmp_ManagerActivity M
    SET Who = T.Who,
        What = T.What,
        Status_Date = T.Start
    FROM ( SELECT RankQ.Who,
                  RankQ.What,
                  RankQ.Start
           FROM ( SELECT format('Capture: %s', Processor) AS Who,
                         format('Processing task %s, step %s, tool %s', job, step, tool) AS What,
                         Start,
                         Row_Number() OVER (Partition BY Processor ORDER BY Start DESC) AS StartRank
                  FROM cap.t_task_steps
                  WHERE State = 4 And Start BETWEEN _startDate AND _endDate
                ) RankQ
           WHERE RankQ.StartRank = 1
         ) T
    WHERE M.Who = T.Who;

    RETURN QUERY
    SELECT
        A.Source,
        A.Who,
        A.What,
        A.Status_Date
    FROM Tmp_ManagerActivity A
    ORDER BY A.Who;

    DROP TABLE Tmp_ManagerActivity;
END
$$;


ALTER FUNCTION public.get_current_manager_activity(_activeonly boolean, _startdate timestamp without time zone, _months integer) OWNER TO d3l243;

