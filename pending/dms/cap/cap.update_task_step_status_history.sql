--
CREATE OR REPLACE PROCEDURE cap.update_task_step_status_history
(
    _minimumTimeIntervalMinutes integer = 60,
    _minimumTimeIntervalMinutesForIdenticalStats integer = 355,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Appends new entries to t_task_step_status_history,
**      summarizing the number of capture task job steps in each state
**
**  Arguments:
**    _minimumTimeIntervalMinutes                    Set this to 0 to force the addition of new data to t_task_step_status_history
**    _minimumTimeIntervalMinutesForIdenticalStats   This controls how often identical stats will get added to t_task_step_status_history
**
**  Auth:   mem
**  Date:   02/05/2016 mem - Initial version (copied from the DMS_Pipeline DB)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _insertCount int;
    _timeIntervalLastUpdateMinutes numeric := 0;
    _timeIntervalIdenticalStatsMinutes numeric := 0;
    _newStatCount int;
    _identicalStatCount int;
    _updateTable boolean;
    _mostRecentPostingTime timestamp;

    _formatSpecifier text := '%-20s %-20s %-10s %-10s';
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _updateTable := true;

    CREATE TEMP TABLE Tmp_TaskStepStatusHistory (
        Posting_Time timestamp NOT NULL,
        Step_Tool text NOT NULL,
        State int NOT NULL,
        Step_Count int NOT NULL
    )

    -----------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------

    _message := '';
    _returnCode := '';
    _infoOnly := Coalesce(_infoOnly, false);

    _mostRecentPostingTime := Null;

    -----------------------------------------------------
    -- Lookup the most recent posting time
    -----------------------------------------------------

    SELECT MAX(Posting_Time)
    INTO _mostRecentPostingTime
    FROM cap.t_task_step_status_history

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

    If _updateTable Then
        -----------------------------------------------------
        -- Compute the new stats
        -----------------------------------------------------

        INSERT INTO Tmp_TaskStepStatusHistory (Posting_Time, Step_Tool, State, Step_Count)
        SELECT CURRENT_TIMESTAMP As Posting_Time, Tool, State, COUNT(*) AS Step_Count
        FROM cap.t_task_steps
        GROUP BY Tool, State
        --
        GET DIAGNOSTICS _newStatCount = ROW_COUNT;

        -----------------------------------------------------
        -- See if the stats match the most recent stats entered in the table
        -----------------------------------------------------

        _identicalStatCount := 0;

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
                  NewStats.Step_Count = RecentStats.Step_Count

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

        If _updateTable Then
            If _infoOnly Then

                RAISE INFO '';

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
                    SELECT timestamp_text(Posting_Time) As Posting_Time, Step_Tool, State, Step_Count;
                    FROM Tmp_TaskStepStatusHistory
                    ORDER BY Step_Tool, State
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.State,
                                        _previewData.Section,
                                        _previewData.Name,
                                        _previewData.Value
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                INSERT INTO cap.t_task_step_status_history  (posting_time, step_tool, state, step_count)
                SELECT Posting_Time, Step_Tool, State, Step_Count
                FROM Tmp_TaskStepStatusHistory
                ORDER BY Step_Tool, State;
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                _message := format('Appended %s rows to the Task Step Status History table', _insertCount);
            End If;
        Else
            _message := format('Update skipped since last update was %s minutes ago and the stats are still identical', Round(_timeIntervalIdenticalStatsMinutes, 1));
        End If;

    Else
        _message := format('Update skipped since last update was %s minutes ago', Round(_timeIntervalLastUpdateMinutes, 1));
    End If;

    DROP TABLE Tmp_TaskStepStatusHistory;
END
$$;

COMMENT ON PROCEDURE cap.update_task_step_status_history IS 'UpdateJobStepStatusHistory';
