--
-- Name: get_current_manager_activity(integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_current_manager_activity(_monthrange integer DEFAULT 3, _jobfinishend timestamp without time zone DEFAULT NULL::timestamp without time zone) RETURNS TABLE(source text, "When" timestamp without time zone, who text, what text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get snapshot of current activity of managers
**
**  Arguments:
**    _monthRange       Number of months to examine, backward from either the current date, or from _jobFinishEnd
**    _jobFinishEnd     When null, examine activity from the current date, backward _monthRange months
**                      When a valid timestamp, examine activity from the given date, backward _monthRange months
**  Example usage:
**    SELECT * FROM get_current_manager_activity(_jobFinishEnd => '2009-01-01');
**
**  Auth:   grk
**  Date:   10/06/2003 grk - Initial version
**          06/01/2004 grk - fixed initial population of XT with jobs
**          06/23/2004 grk - Used AJ_start instead of AJ_finish in default population
**          11/04/2004 grk - Widened 'Who' column of XT to match data in some item queries
**          02/24/2004 grk - fixed problem with null value for AJ_assignedProcessorName
**          02/09/2007 grk - added column to note that activity is stale (Ticket #377)
**          02/27/2007 grk - fixed prep manager reporting (Ticket #398)
**          04/04/2008 dac - changed output sort order to DESC
**          09/30/2009 grk - eliminated references to health log
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          10/27/2022 mem - Change # column to lowercase
**          11/02/2022 mem - Remove # from column name
**          11/16/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobFinishStart timestamp;
BEGIN

    _monthRange := Coalesce(_monthRange, 3);
    _jobFinishEnd := Coalesce(_jobFinishEnd, CURRENT_TIMESTAMP);

    _jobFinishStart = _jobFinishEnd - make_interval(months => _monthRange);

    -- Temporary table to hold accumulated results
    --
    CREATE TEMP TABLE Tmp_ManagerActivity (
        Source text,
        "When" timestamp,
        Who  text,
        What text
    );

    RAISE INFO 'Examining jobs started betwen % and %', _jobFinishStart::date, _jobFinishEnd::date;

    -- Populate temporary table with known analysis managers
    --
    INSERT INTO Tmp_ManagerActivity("When", Who, What, Source)
    SELECT M."When",
           'Analysis: ' || M.assigned_processor_name AS Who,
           format('Nothing in health log or in process, but active between %s and %s', _jobFinishStart::date, _jobFinishEnd::date) AS What,
           'Historic' as Source
    FROM (  -- get distinct list of analysis managers
            -- that have been active in the previous three months
            --
            SELECT COALESCE(assigned_processor_name, '(unknown)') as assigned_processor_name,
                   COALESCE(MAX(start), make_date(2003, 1, 1)) as "When"
            FROM  T_Analysis_Job
            WHERE Start BETWEEN _jobFinishStart AND _jobFinishEnd
            GROUP BY assigned_processor_name
        ) M;

    -- Update any entries that have active job with later date than existing entry in Tmp_ManagerActivity
    --
    UPDATE Tmp_ManagerActivity M
    Set "When" = T."When",
        Who = T.Who,
        What = T.What,
        Source = 'Jobs'
    From ( -- get list of jobs in progress
           --
           SELECT start as "When", 'Analysis: ' || assigned_processor_name as Who, 'Job in progress: ' || CAST(job AS text) AS What
           FROM   t_analysis_job
           WHERE  job_state_id = 2
         ) T
    WHERE M.Who = T.Who AND M."When" <= T."When";

    -- Update any entries that have active capture with later date (from event log) than health log
    --
    Update Tmp_ManagerActivity M
    Set "When" = T."When",
        Who = T.Who,
        What = T.What,
        Source = 'Capture'
    From ( -- get list of captures in progress
           --
           SELECT t_event_log.entered AS "When",
                  'Capture: ' || t_storage_path.machine_name AS Who,
                  'In Progress: ' || t_dataset.dataset  AS What
           FROM t_dataset INNER JOIN
                t_storage_path ON t_dataset.storage_path_ID = t_storage_path.storage_path_id INNER JOIN
                t_event_log ON t_dataset.dataset_id = t_event_log.target_id
           WHERE t_dataset.dataset_state_id = 2 AND t_event_log.target_type = 4
         ) T
    WHERE M.Who = T.Who And M."When" < T."When";

    -- Update any entries that have active preparation with later date (from event log) than health log
    --
    Update Tmp_ManagerActivity M
    Set "When" = T."When",
        Who = T.Who,
        What = T.What,
        Source = 'Preparation'
    From ( -- get list of preparation in progress
          --
          SELECT
              t_event_log.entered AS "When",
              'In Progress: ' || t_dataset.dataset AS What,
              'Preparation: ' || t_dataset.ds_prep_server_name AS Who
          FROM t_dataset INNER JOIN
               t_storage_path ON t_dataset.storage_path_id = t_storage_path.storage_path_id INNER JOIN
               t_event_log ON t_dataset.dataset_id = t_event_log.target_id
          WHERE t_dataset.dataset_state_id = 7 AND
                t_event_log.target_type = 4 AND
                t_event_log.target_state = 7
        ) T
    WHERE M.Who = T.Who And M."When" < T."When";

    -- Update any entries that have active archive with later date (from event log) than health log
    --
    Update Tmp_ManagerActivity M
    Set "When" = T."When",
        Who = T.Who,
        What = T.What,
        Source = 'Archive'
    From ( -- get list of archive in progress
           --
           SELECT t_event_log.entered AS "When",
                  'Archive: ' || t_storage_path.machine_name AS Who,
                  'In Progress: ' || t_dataset.dataset AS What
           FROM t_dataset INNER JOIN
                t_storage_path ON t_dataset.storage_path_id = t_storage_path.storage_path_id INNER JOIN
                t_event_log ON t_dataset.dataset_id = t_event_log.target_id INNER JOIN
                t_dataset_archive ON t_dataset.dataset_id = t_dataset_archive.dataset_id
           WHERE t_event_log.target_type = 6 AND t_dataset_archive.archive_state_id IN (2, 7)
         ) T
    WHERE M.Who = T.Who And M."When" < T."When";

    RETURN QUERY
    SELECT
        A.Source,
        A."When",
        A.Who,
        A.What
    FROM Tmp_ManagerActivity A
    ORDER by A.Who DESC;

    DROP TABLE Tmp_ManagerActivity;
END
$$;


ALTER FUNCTION public.get_current_manager_activity(_monthrange integer, _jobfinishend timestamp without time zone) OWNER TO d3l243;

--
-- Name: FUNCTION get_current_manager_activity(_monthrange integer, _jobfinishend timestamp without time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_current_manager_activity(_monthrange integer, _jobfinishend timestamp without time zone) IS 'GetCurrentManagerActivity';

