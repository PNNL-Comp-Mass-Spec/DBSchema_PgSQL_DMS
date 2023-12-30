--
-- Name: update_task_step_status_history(integer, integer, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_task_step_status_history(IN _minimumtimeintervalminutes integer DEFAULT 60, IN _minimumtimeintervalminutesforidenticalstats integer DEFAULT 355, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Append new entries to cap.t_task_step_status_history, summarizing the number of capture task job steps in each state
**
**  Arguments:
**    _minimumTimeIntervalMinutes                   Set this to 0 to force the addition of new data to cap.t_task_step_status_history
**    _minimumTimeIntervalMinutesForIdenticalStats  This controls how often identical stats will get added to cap.t_task_step_status_history
**    _message                                      Status message
**    _returnCode                                   Return code
**    _infoOnly                                     When true, preview updates
**
**  Auth:   mem
**  Date:   02/05/2016 mem - Initial version (copied from the DMS_Pipeline DB)
**          06/29/2023 mem - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(job) instead of COUNT(*)
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

    _updateTable := true;

    -----------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------

    _infoOnly              := Coalesce(_infoOnly, false);
    _mostRecentPostingTime := Null;

    -----------------------------------------------------
    -- Lookup the most recent posting time
    -----------------------------------------------------

    SELECT MAX(Posting_Time)
    INTO _mostRecentPostingTime
    FROM cap.t_task_step_status_history;

    If Coalesce(_minimumTimeIntervalMinutes, 0) = 0 Or _mostRecentPostingTime Is Null Then
        _updateTable := true;
    Else
        _timeIntervalLastUpdateMinutes := extract(epoch FROM CURRENT_TIMESTAMP - _mostRecentPostingTime) / 60.0;

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

    CREATE TEMP TABLE Tmp_TaskStepStatusHistory (
        Posting_Time timestamp NOT NULL,
        Step_Tool text NOT NULL,
        State int NOT NULL,
        Step_Count int NOT NULL
    );

    -----------------------------------------------------
    -- Compute the new stats
    -----------------------------------------------------

    INSERT INTO Tmp_TaskStepStatusHistory (Posting_Time, Step_Tool, State, Step_Count)
    SELECT CURRENT_TIMESTAMP As Posting_Time, Tool, State, COUNT(job) AS Step_Count
    FROM cap.t_task_steps
    GROUP BY Tool, State;
    --
    GET DIAGNOSTICS _newStatCount = ROW_COUNT;

    -----------------------------------------------------
    -- See if the stats match the most recent stats entered in the table
    -----------------------------------------------------

    _timeIntervalIdenticalStatsMinutes := 0;

    SELECT COUNT(*)
    INTO _identicalStatCount
    FROM Tmp_TaskStepStatusHistory NewStats
         INNER JOIN ( SELECT Step_Tool,
                             State,
                             Step_Count
                      FROM cap.t_task_step_status_history
                      WHERE Posting_Time = _mostRecentPostingTime
                    ) RecentStats
           ON NewStats.Step_Tool = RecentStats.Step_Tool AND
              NewStats.State = RecentStats.State AND
              NewStats.Step_Count = RecentStats.Step_Count;

    If _identicalStatCount = _newStatCount Then
        -----------------------------------------------------
        -- All of the stats match
        -- Only make new entries to t_task_step_status_history if _minimumTimeIntervalMinutesForIdenticalStats minutes have elapsed
        -----------------------------------------------------

        _timeIntervalIdenticalStatsMinutes := extract(epoch FROM CURRENT_TIMESTAMP - _mostRecentPostingTime) / 60.0;

        If _timeIntervalIdenticalStatsMinutes >= _minimumTimeIntervalMinutesForIdenticalStats Then
            _updateTable := true;
        Else
            _updateTable := false;
        End If;
    End If;

    If Not _updateTable Then
        _message := format('Update skipped since last update was %s minutes ago and the stats are still identical', Round(_timeIntervalIdenticalStatsMinutes, 1));
        DROP TABLE Tmp_TaskStepStatusHistory;
        RETURN;
    End If;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-20s %-20s %-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Posting_Time',
                            'Step_Tool',
                            'State',
                            'Step_Count'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------------',
                                     '--------------------',
                                     '----------',
                                     '----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT timestamp_text(Posting_Time) As Posting_Time, Step_Tool, State, Step_Count
            FROM Tmp_TaskStepStatusHistory
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

        DROP TABLE Tmp_TaskStepStatusHistory;
        RETURN;
    End If;

    INSERT INTO cap.t_task_step_status_history (posting_time, step_tool, state, step_count)
    SELECT Posting_Time, Step_Tool, State, Step_Count
    FROM Tmp_TaskStepStatusHistory
    ORDER BY Step_Tool, State;
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    _message := format('Appended %s rows to the Task Step Status History table', _insertCount);

    DROP TABLE Tmp_TaskStepStatusHistory;
END
$$;


ALTER PROCEDURE cap.update_task_step_status_history(IN _minimumtimeintervalminutes integer, IN _minimumtimeintervalminutesforidenticalstats integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_task_step_status_history(IN _minimumtimeintervalminutes integer, IN _minimumtimeintervalminutesforidenticalstats integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_task_step_status_history(IN _minimumtimeintervalminutes integer, IN _minimumtimeintervalminutesforidenticalstats integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'UpdateTaskStepStatusHistory or UpdateJobStepStatusHistory';

