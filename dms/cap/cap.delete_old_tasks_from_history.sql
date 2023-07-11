--
-- Name: delete_old_tasks_from_history(boolean, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.delete_old_tasks_from_history(IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Delete capture task jobs over three years old from
**          t_tasks_history, t_task_steps_history, t_task_step_dependencies_history, and t_task_parameters_history
**
**          However, assure that at least 250,000 capture task jobs are retained
**
**  Auth:   mem
**  Date:   05/29/2022 mem - Initial version
**          10/11/2022 mem - Ported to PostgreSQL
**          04/02/2023 mem - Rename procedure and functions
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/12/2023 mem - Rename variables
**          07/11/2023 mem - Use COUNT(Job) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _deleteCount int;
    _dateThreshold timestamp;
    _jobHistoryMinimumCount int := 250000;
    _currentJobCount int;
    _jobCountToDelete int;
    _tempTableJobsToRemove int;
    _jobFirst int;
    _jobLast int;

    _formatSpecifier text := '%-10s %-20s %-40s';
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Create a temp table to hold the capture task jobs to delete
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobsToDelete (
        Job   int NOT NULL,
        Saved timestamp NOT NULL,
        PRIMARY KEY ( Job, Saved )
    );

    ---------------------------------------------------
    -- Define the date threshold by subtracting three years from January 1 of this year
    ---------------------------------------------------

    _dateThreshold := make_date(Extract(year from CURRENT_TIMESTAMP)::int, 1, 1) - Interval '3 years';

    ---------------------------------------------------
    -- Find capture task jobs to delete
    ---------------------------------------------------

    INSERT INTO Tmp_JobsToDelete( Job, Saved )
    SELECT Job, Saved
    FROM cap.t_tasks_history
    WHERE Saved < _dateThreshold;
    --
    GET DIAGNOSTICS _jobCountToDelete = ROW_COUNT;

    If _jobCountToDelete = 0 Then
        _message := 'No old capture task jobs were found; exiting';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_JobsToDelete;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Assure that 250,000 rows will remain in t_tasks_history
    ---------------------------------------------------

    SELECT COUNT(job)
    INTO _currentJobCount
    FROM cap.t_tasks_history;

    If FOUND And _currentJobCount - _jobCountToDelete < _jobHistoryMinimumCount Then
        -- Remove extra capture task jobs from Tmp_JobsToDelete
        _tempTableJobsToRemove := _jobHistoryMinimumCount - (_currentJobCount - _jobCountToDelete);

        DELETE FROM Tmp_JobsToDelete
        WHERE Job IN ( SELECT Job
                       FROM Tmp_JobsToDelete
                       ORDER BY Job DESC
                       LIMIT _tempTableJobsToRemove );
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        _message := format('Removed %s rows from Tmp_JobsToDelete to assure that %s rows remain in t_tasks_history', _deleteCount, _jobHistoryMinimumCount);
        RAISE INFO '%', _message;

        If Not Exists (Select * From Tmp_JobsToDelete) Then
            _message := 'Tmp_JobsToDelete is now empty, so no old capture task jobs to delete; exiting';
            RAISE INFO '%', _message;

            DROP TABLE Tmp_JobsToDelete;
            RETURN;
        End If;
    End If;

    SELECT COUNT(Job),
           MIN(Job),
           MAX(Job)
    INTO _jobCountToDelete, _jobFirst, _jobLast
    FROM Tmp_JobsToDelete;

    ---------------------------------------------------
    -- Delete the old capture task jobs (preview if _infoOnly is true)
    ---------------------------------------------------

    If _infoOnly Then

        RAISE INFO '';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Saved',
                            'Comment'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------',
                                     '----------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        -- Show the first 10 jobs in Tmp_JobsToDelete
        --
        FOR _previewData IN
            SELECT Job, timestamp_text(Saved) As Saved, 'Preview delete' As Comment
            FROM Tmp_JobsToDelete
            ORDER By Job
            LIMIT 10
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Saved,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        If _jobCountToDelete > 10 Then
            _infoData := format(_formatSpecifier, '...', '...', '...');
            RAISE INFO '%', _infoData;

            -- Show the last 10 jobs in Tmp_JobsToDelete
            --
            FOR _previewData IN
                SELECT Job, Saved, 'Preview delete' AS Comment
                FROM ( SELECT Job, Saved
                       FROM Tmp_JobsToDelete
                       ORDER BY Job DESC
                       LIMIT 10 ) FilterQ
                ORDER BY Job
                LIMIT 10
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.Saved,
                                    _previewData.Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;
        End If;

    Else
        DELETE FROM cap.t_task_steps_history
        WHERE Job In (Select Job From Tmp_JobsToDelete);

        DELETE FROM cap.t_task_step_dependencies_history
        WHERE Job In (Select Job From Tmp_JobsToDelete);

        DELETE FROM cap.t_task_parameters_history
        WHERE Job In (Select Job From Tmp_JobsToDelete);

        DELETE FROM cap.t_tasks_history
        WHERE Job In (Select Job From Tmp_JobsToDelete);
    End If;

    If _infoOnly Then
        RAISE INFO '';
        _message := 'Would delete';
    Else
        _message := 'Deleted';
    End If;

    _message := format('%s %s old capture task jobs from the history tables; job number range %s to %s', _message, _jobCountToDelete, _jobFirst, _jobLast);

    If Not _infoOnly And _jobCountToDelete > 0 Then
        CALL public.post_log_entry ('Normal', _message, 'Delete_Old_Tasks_From_History', 'cap');
    End If;

    If char_length(_message) > 0 Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_JobsToDelete;
END
$$;


ALTER PROCEDURE cap.delete_old_tasks_from_history(IN _infoonly boolean, INOUT _message text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_old_tasks_from_history(IN _infoonly boolean, INOUT _message text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.delete_old_tasks_from_history(IN _infoonly boolean, INOUT _message text) IS 'DeleteOldTasksFromHistory or DeleteOldJobsFromHistory';

