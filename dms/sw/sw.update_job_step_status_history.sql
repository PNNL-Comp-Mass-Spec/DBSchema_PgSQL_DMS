--
-- Name: update_job_step_status_history(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_job_step_status_history(IN _minimumtimeintervalminutes integer DEFAULT 60, IN _minimumtimeintervalminutesforidenticalstats integer DEFAULT 355, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Appends new entries to sw.T_Job_Step_Status_History,
**      summarizing the number of job steps in each state in sw.T_Job_Steps
**
**  Arguments:
**    _minimumTimeIntervalMinutes                   Set this to 0 to force the addition of new data to sw.T_Job_Step_Status_History
**    _minimumTimeIntervalMinutesForIdenticalStats  This controls how often identical stats will get added to the table
**    _infoOnly                                     When true, preview the data that would be added to the table
**
**  Auth:   mem
**  Date:   12/05/2008
**          08/14/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _insertCount int;
    _timeIntervalLastUpdateMinutes numeric;
    _timeIntervalIdenticalStatsMinutes numeric;
    _newStatCount int;
    _identicalStatCount int;
    _updateTable boolean;
    _mostRecentPostingTime timestamp;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _timeIntervalLastUpdateMinutes := 0;
    _timeIntervalIdenticalStatsMinutes := 0;

    _updateTable := true;

    -----------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------

    _minimumTimeIntervalMinutes                  := Coalesce(_minimumTimeIntervalMinutes, 0);
    _minimumTimeIntervalMinutesForIdenticalStats := Coalesce(_minimumTimeIntervalMinutesForIdenticalStats, 355);
    _infoOnly                                    := Coalesce(_infoOnly, false);

    _mostRecentPostingTime := Null;

    -----------------------------------------------------
    -- Lookup the most recent posting time
    -----------------------------------------------------

    SELECT MAX(posting_time)
    INTO _mostRecentPostingTime
    FROM sw.t_job_step_status_history;

    If Not FOUND Or _minimumTimeIntervalMinutes <= 0 Then
        _updateTable := true;
    Else
        _timeIntervalLastUpdateMinutes := extract(epoch FROM (CURRENT_TIMESTAMP - _mostRecentPostingTime)) / 60.0;

        If _timeIntervalLastUpdateMinutes >= _minimumTimeIntervalMinutes Then
            _updateTable := true;
        Else
            _updateTable := false;
        End If;
    End If;

    If Not _updateTable Then
        _message := format('Update skipped since last update was %s minutes ago', Round(_timeIntervalLastUpdateMinutes, 1));
        RETURN;
    End If;

    CREATE TEMP TABLE Tmp_JobStepStatusHistory (
        Posting_Time timestamp NOT NULL,
        Step_Tool text NOT NULL,
        State int NOT NULL,
        Step_Count int NOT NULL
    );

    -----------------------------------------------------
    -- Compute the new stats
    -----------------------------------------------------

    INSERT INTO Tmp_JobStepStatusHistory (Posting_Time, Step_Tool, State, Step_Count)
    SELECT CURRENT_TIMESTAMP AS Posting_Time,
           tool,
           state,
           COUNT(step) AS Step_Count
    FROM sw.t_job_steps
    GROUP BY Tool, state;
    --
    GET DIAGNOSTICS _newStatCount = ROW_COUNT;

    -----------------------------------------------------
    -- See if the stats match the most recent stats entered in the table
    -----------------------------------------------------

    SELECT COUNT(*)
    INTO _identicalStatCount
    FROM Tmp_JobStepStatusHistory NewStats
         INNER JOIN ( SELECT step_tool,
                             state,
                             step_count
                      FROM sw.t_job_step_status_history
                      WHERE posting_time = _mostRecentPostingTime
                    ) RecentStats
           ON NewStats.Step_tool = RecentStats.step_tool AND
              NewStats.State = RecentStats.state AND
              NewStats.Step_Count = RecentStats.step_count;

    If _identicalStatCount = _newStatCount Then
        -----------------------------------------------------
        -- All of the stats match
        -- Only make new entries to sw.t_job_step_status_history if _minimumTimeIntervalMinutesForIdenticalStats minutes have elapsed
        -----------------------------------------------------

        _timeIntervalIdenticalStatsMinutes := extract(epoch FROM (CURRENT_TIMESTAMP - _mostRecentPostingTime)) / 60.0;

        If _timeIntervalIdenticalStatsMinutes >= _minimumTimeIntervalMinutesForIdenticalStats Then
            _updateTable := true;
        Else
            _updateTable := false;
        End If;
    End If;

    If Not _updateTable Then
        _message := format('Update skipped since last update was %s minutes ago and the stats are still identical', Round(_timeIntervalIdenticalStatsMinutes, 1));

        DROP TABLE Tmp_JobStepStatusHistory;
        RETURN;
    End If;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-20s %-25s %-5s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Posting_Time',
                            'Step_Tool',
                            'State',
                            'Step_Count'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------------',
                                     '-------------------------',
                                     '-----',
                                     '----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT public.timestamp_text(Posting_Time) AS Posting_Time,
                   Step_Tool,
                   State,
                   Step_Count
            FROM Tmp_JobStepStatusHistory
            ORDER BY Step_Tool, State
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Posting_Time,
                                _previewData.Step_Tool,
                                _previewData.State,
                                _previewData.Step_Count
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_JobStepStatusHistory;
        RETURN;
    End If;

    INSERT INTO sw.t_job_step_status_history (posting_time, step_tool, state, step_count)
    SELECT Posting_Time, Step_Tool, State, Step_Count
    FROM Tmp_JobStepStatusHistory
    ORDER BY step_tool, state;
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    _message := format('Appended %s %s to the Job Step Status History table', _insertCount, public.check_plural(_insertCount, 'row', 'rows'));

    DROP TABLE Tmp_JobStepStatusHistory;
END
$$;


ALTER PROCEDURE sw.update_job_step_status_history(IN _minimumtimeintervalminutes integer, IN _minimumtimeintervalminutesforidenticalstats integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_job_step_status_history(IN _minimumtimeintervalminutes integer, IN _minimumtimeintervalminutesforidenticalstats integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_job_step_status_history(IN _minimumtimeintervalminutes integer, IN _minimumtimeintervalminutesforidenticalstats integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateJobStepStatusHistory';

