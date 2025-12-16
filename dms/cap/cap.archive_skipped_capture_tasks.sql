--
-- Name: archive_skipped_capture_tasks(integer, boolean, integer, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.archive_skipped_capture_tasks(IN _jobageweeks integer DEFAULT 3, IN _logdeletions boolean DEFAULT false, IN _maxtaskstoremove integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Removes old, skipped capture tasks from cap.t_tasks by calling procedure remove_old_tasks, setting _jobStateFilter to 15
**      Prior to removal, makes sure that the tasks are in cap.t_tasks_history
**
**  Arguments:
**    _jobAgeWeeks          Capture task job age threshold, minimum 3 weeks
**    _logDeletions         When true, logs each deleted job number in cap.t_log_entries
**    _maxTasksToRemove     When non-zero, limit the number of tasks deleted to this value (order by job)
**    _infoOnly             When true, preview updates
**    _message              Status message
**    _returnCode           Return code
**
**  Example usage:
**      CALL archive_skipped_capture_tasks (
**               _jobAgeWeeks => 3,
**               _logDeletions => false,
**               _maxTasksToRemove => 5,
**               _infoOnly => true);
**
**  Auth:   mem
**  Date:   11/05/2025 mem - Initial release
**
*****************************************************/
DECLARE
    _intervalDaysForSuccess int;
    _startTimeThreshold timestamp;
    _startTimeThresholdText text;
    _insertCount int;
    _infoMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _jobAgeWeeks        := Coalesce(_jobAgeWeeks, 3);
    _logDeletions       := Coalesce(_logDeletions, false);
    _maxTasksToRemove   := Coalesce(_maxTasksToRemove, 0);
    _infoOnly           := Coalesce(_infoOnly, false);

    If _jobAgeWeeks < 3 Then
        _jobAgeWeeks := 3;
    End If;

    ---------------------------------------------------
    -- Create a temporary table to hold the capture task jobs to process
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Tasks_to_Archive (
        Job int NOT NULL,
        Script citext NULL
    );

    CREATE INDEX IX_Tmp_Tasks_to_Archive ON Tmp_Tasks_to_Archive (Job);

    ---------------------------------------------------
    -- Find candidate capture task jobs
    ---------------------------------------------------

    _intervalDaysForSuccess := _jobAgeWeeks * 7;
    _startTimeThreshold     := CURRENT_TIMESTAMP - make_interval(weeks => _jobAgeWeeks);
    _startTimeThresholdText := to_char(_startTimeThreshold, 'yyyy-mm-dd hh24:mi:ss');

    INSERT INTO Tmp_Tasks_to_Archive (
        Job,
        Script
    )
    SELECT job,
           script
    FROM cap.t_tasks
    WHERE state = 15 AND start < _startTimeThreshold
    ORDER BY job;
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    If _insertCount = 0 Then
        _infoMessage := format('No capture task jobs in cap.t_tasks have State = 15 and a start time earlier than %s', _startTimeThresholdText);
    Else
        _infoMessage := format('Found %s capture task %s in cap.t_tasks with State = 15 and a start time earlier than %s',
                               _insertCount, public.check_plural(_insertCount, 'job', 'jobs'), _startTimeThresholdText);
    End If;

    RAISE INFO '';
    RAISE INFO '%', _infoMessage;

    If _infoOnly Then
        _formatSpecifier := '%-20s %-8s';

        _infoHead := format(_formatSpecifier,
                            'Script',
                            'Jobs'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------------',
                                     '--------'
                                    );

        RAISE INFO '';
        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Script,
                   COUNT(*) AS Jobs
            FROM Tmp_Tasks_to_Archive
            GROUP BY Script
            ORDER BY Script
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Script,
                                _previewData.Jobs
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RAISE INFO '';

        If _maxTasksToRemove > 0 Then
            RAISE INFO 'Would call procedure cap.remove_old_tasks to remove % of them from t_tasks, t_task_steps, etc.', _maxTasksToRemove;
        Else
            RAISE INFO 'Would call procedure cap.remove_old_tasks to remove them from t_tasks, t_task_steps, etc.';
        End If;

        DROP TABLE Tmp_Tasks_to_Archive;
        RETURN;
    End If;

    CALL cap.remove_old_tasks (
             _intervalDaysForSuccess => _intervalDaysForSuccess,
             _intervalDaysForFail    => 0,
             _logDeletions           => _logDeletions,
             _maxTasksToRemove       => _maxTasksToRemove,
             _jobStateFilter         => 15,
             _infoOnly               => _infoOnly,
             _message                => _message,
             _returnCode             => _returnCode);

    DROP TABLE Tmp_Tasks_to_Archive;
END
$$;


ALTER PROCEDURE cap.archive_skipped_capture_tasks(IN _jobageweeks integer, IN _logdeletions boolean, IN _maxtaskstoremove integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

