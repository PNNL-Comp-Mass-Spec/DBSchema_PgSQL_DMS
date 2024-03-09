--
-- Name: delete_old_jobs_from_history(boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.delete_old_jobs_from_history(IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete jobs over three years old from the history tables:
**      - sw.T_Jobs_History
**      - sw.T_Job_Steps_History
**      - sw.T_Job_Step_Dependencies_History
**      - sw.T_Job_Parameters_History
**
**      However, assure that at least 250,000 jobs are retained
**
**      Additionally:
**      - Delete old status rows from sw.T_Machine_Status_History
**      - Delete old rows from sw.T_Job_Step_Processing_Stats
**
**  Arguments:
**    _infoOnly     When true, preview the 10 oldest and 10 newest jobs that would be deleted
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   05/29/2022 mem - Initial version
**          08/01/2023 mem - Ported to PostgreSQL
**          01/04/2024 mem - Check for empty strings instead of using char_length()
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

    _infoOnly := Coalesce(_infoOnly, true);

    ---------------------------------------------------
    -- Create a temporary table to hold the jobs to delete
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobsToDelete (
        Job   int NOT NULL,
        Saved timestamp NOT NULL,
        PRIMARY KEY ( Job, Saved )
    );

    ---------------------------------------------------
    -- Define the date threshold by subtracting three years from January 1 of this year
    ---------------------------------------------------

    _dateThreshold := make_timestamp(Extract(year from CURRENT_TIMESTAMP)::int, 1, 1, 0, 0, 0) - INTERVAL '3 years';

    ---------------------------------------------------
    -- Find jobs to delete
    ---------------------------------------------------

    INSERT INTO Tmp_JobsToDelete (job, saved)
    SELECT job, saved
    FROM sw.t_jobs_history
    WHERE saved < _dateThreshold;
    --
    GET DIAGNOSTICS _jobCountToDelete = ROW_COUNT;

    If _jobCountToDelete = 0 Then
        _message := 'No old jobs were found; exiting';

        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO '%', _message;
        End If;

        DROP TABLE Tmp_JobsToDelete;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Assure that 250,000 rows will remain in sw.t_jobs_history
    ---------------------------------------------------

    SELECT COUNT(job)
    INTO _currentJobCount
    FROM sw.t_jobs_history;

    If _currentJobCount - _jobCountToDelete < _jobHistoryMinimumCount Then
        -- Remove extra jobs from Tmp_JobsToDelete
        _tempTableJobsToRemove := _jobHistoryMinimumCount - (_currentJobCount - _jobCountToDelete);

        DELETE FROM Tmp_JobsToDelete
        WHERE job IN ( SELECT Job
                       FROM Tmp_JobsToDelete
                       ORDER BY Job DESC
                       LIMIT _tempTableJobsToRemove);
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        _message := format('Removed %s %s from Tmp_JobsToDelete to assure that %s rows remain in sw.t_jobs_history',
                           _deleteCount, public.check_plural(_deleteCount, 'row', 'rows'), _jobHistoryMinimumCount);

        RAISE INFO '%', _message;

        If Not Exists (SELECT Job FROM Tmp_JobsToDelete) Then
            _message := 'Tmp_JobsToDelete is now empty, so no old jobs to delete; exiting';
            RETURN;
        End If;
    End If;

    SELECT COUNT(*),
           MIN(Job),
           MAX(Job)
    INTO _jobCountToDelete, _jobFirst, _jobLast
    FROM Tmp_JobsToDelete;

    ---------------------------------------------------
    -- Delete the old jobs (preview if _infoOnly is true)
    ---------------------------------------------------

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-10s %-20s %-15s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Saved',
                            'Comment'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------',
                                     '---------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        -- Show the first 10 jobs

        FOR _previewData IN
            SELECT Job,
                   public.timestamp_text(Saved) AS Saved,
                   'Preview delete' AS Comment
            FROM Tmp_JobsToDelete
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

        RAISE INFO '';
        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        -- Show the last 10 jobs

        FOR _previewData IN
            SELECT Job,
                   public.timestamp_text(Saved) AS Saved,
                   'Preview delete' AS Comment
            FROM ( SELECT Job, Saved
                   FROM Tmp_JobsToDelete
                   ORDER BY Job DESC
                   LIMIT 10) FilterQ
            ORDER BY Job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Saved,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        -- Show the first row to be deleted from sw.t_machine_status_history for each machine

        RAISE INFO '';

        _formatSpecifier := '%-10s %-20s %-20s %-22s %-14s %-25s';

        _infoHead := format(_formatSpecifier,
                            'Entry_ID',
                            'Posting_Time',
                            'Machine',
                            'Processor_Count_Active',
                            'Free_Memory_MB',
                            'Comment'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------',
                                     '--------------------',
                                     '----------------------',
                                     '--------------',
                                     '-------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT H.Entry_ID,
                   H.Posting_Time,
                   H.Machine,
                   H.Processor_Count_Active,
                   H.Free_Memory_MB,
                   'First row to be deleted' AS Comment
            FROM sw.t_machine_status_history H
                 INNER JOIN ( SELECT machine,
                                     MIN(entry_id) AS Entry_ID
                              FROM sw.t_machine_status_history
                              WHERE entry_id IN
                                       ( SELECT entry_id
                                         FROM ( SELECT entry_id,
                                                Row_Number() OVER (PARTITION BY machine ORDER BY entry_id DESC) AS RowRank
                                                FROM sw.t_machine_status_history ) RankQ
                                         WHERE RowRank > 1000 )
                              GROUP BY machine
                            ) FilterQ
                   ON H.entry_id = FilterQ.entry_id
            ORDER BY machine
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Entry_ID,
                                _previewData.Posting_Time,
                                _previewData.Machine,
                                _previewData.Processor_Count_Active,
                                _previewData.Free_Memory_MB,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else
        DELETE FROM sw.t_job_steps_history
        WHERE job IN (SELECT job FROM Tmp_JobsToDelete);

        DELETE FROM sw.t_job_step_dependencies_history
        WHERE job IN (SELECT job FROM Tmp_JobsToDelete);

        DELETE FROM sw.t_job_parameters_history
        WHERE job IN (SELECT job FROM Tmp_JobsToDelete);

        DELETE FROM sw.t_jobs_history
        WHERE job IN (SELECT job FROM Tmp_JobsToDelete);

        -- Keep the 1000 most recent status values for each machine
        DELETE FROM sw.t_machine_status_history Target
        WHERE EXISTS ( SELECT 1
                       FROM ( SELECT entry_id,
                                     Row_Number() OVER (PARTITION BY machine ORDER BY entry_id DESC) AS RowRank
                              FROM sw.t_machine_status_history ) RankQ
                       WHERE Target.entry_id = RankQ.entry_id AND
                             RowRank > 1000
                     );

        -- Keep the 500 most recent processing stats values for each processor
        DELETE FROM sw.t_job_step_processing_stats Target
        WHERE EXISTS ( SELECT 1
                       FROM ( SELECT entry_id,
                                     Row_Number() OVER (PARTITION BY processor ORDER BY entered DESC) AS RowRank
                       FROM sw.t_job_step_processing_stats ) RankQ
                       WHERE Target.entry_id = RankQ.entry_id AND
                             RowRank > 500
                     );

    End If;

    If _infoOnly Then
        _message := 'Would delete';
    Else
        _message := 'Deleted';
    End If;

    _message := format('%s %s old jobs from the history tables; job number range %s to %s',
                        _message, _jobCountToDelete, _jobFirst, _jobLast);

    If Not _infoOnly And _jobCountToDelete > 0 Then
        CALL public.post_log_entry ('Normal', _message, 'Delete_Old_Jobs_From_History', 'sw');
    End If;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

    If Trim(Coalesce(_message, '')) <> '' Then
        RAISE INFO '';
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_JobsToDelete;
END
$$;


ALTER PROCEDURE sw.delete_old_jobs_from_history(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_old_jobs_from_history(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.delete_old_jobs_from_history(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'DeleteOldJobsFromHistory';

