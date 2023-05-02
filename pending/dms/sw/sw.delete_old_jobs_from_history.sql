--
CREATE OR REPLACE PROCEDURE sw.delete_old_jobs_from_history
(
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete jobs over three years old from
**      T_Jobs_History, T_Job_Steps_History, T_Job_Step_Dependencies_History, and T_Job_Parameters_History
**
**      However, assure that at least 250,000 jobs are retained
**
**      Additionally:
**      - Delete old status rows from T_Machine_Status_History
**      - Delete old rows from T_Job_Step_Processing_Stats
**
**  Auth:   mem
**  Date:   05/29/2022 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _dateThreshold timestamp;
    _jobHistoryMinimumCount int := 250000;
    _currentJobCount int;
    _jobCountToDelete int;
    _tempTableJobsToRemove int;
    _jobFirst int;
    _jobLast int;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);

    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Create a temp table to hold the jobs to delete
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobsToDelete (
        Job   int NOT NULL,
        Saved timestamp NOT NULL,
        PRIMARY KEY CLUSTERED ( Job, Saved )
    )

    ---------------------------------------------------
    -- Define the date threshold by subtracting three years from January 1 of this year
    ---------------------------------------------------

    _dateThreshold := make_timestamp(Extract(year from CURRENT_TIMESTAMP)::int, 1, 1, 0, 0, 0) - INTERVAL '3 years';

    ---------------------------------------------------
    -- Find jobs to delete
    ---------------------------------------------------

    INSERT INTO Tmp_JobsToDelete( job, saved )
    SELECT job, saved
    FROM sw.t_jobs_history
    WHERE saved < _dateThreshold
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    _jobCountToDelete := _myRowcount;

    If _jobCountToDelete = 0 Then
        _message := 'No old jobs were found; exiting';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Assure that 250,000 rows will remain in sw.t_jobs_history
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _currentJobCount
    FROM sw.t_jobs_history;

    If _currentJobCount - _jobCountToDelete < _jobHistoryMinimumCount Then
        -- Remove extra jobs from Tmp_JobsToDelete
        _tempTableJobsToRemove := _jobHistoryMinimumCount - (_currentJobCount - _jobCountToDelete);

        DELETE FROM Tmp_JobsToDelete
        WHERE Job IN ( SELECT Job
                       FROM Tmp_JobsToDelete
                       ORDER BY Job DESC
                       LIMIT _tempTableJobsToRemove)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _message := 'Removed ' || Cast(_myRowCount As text) ||
                       ' rows from Tmp_JobsToDelete to assure that ' ||
                       Cast(_jobHistoryMinimumCount As text) || ' rows remain in sw.t_jobs_history'

        RAISE INFO '%', _message;

        If Not Exists (Select * From Tmp_JobsToDelete) Then
            _message := 'Tmp_JobsToDelete is now empty, so no old jobs to delete; exiting';
            RETURN;
        End If;
    End If;

    SELECT COUNT(*),
           MIN(Job),
           MAX(Job)
    INTO _jobCountToDelete, _jobFirst, _jobLast
    FROM Tmp_JobsToDelete
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Delete the old jobs (preview if _infoOnly is true)
    ---------------------------------------------------
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _infoOnly Then
        -- Show the first 10 jobs
        SELECT Top 10 Job, Saved, 'Preview delete' As Comment
        From Tmp_JobsToDelete
        ORDER By Job
        LIMIT 10;

        -- Show the last 10 jobs
        SELECT TOP 10 Job, Saved, 'Preview delete' AS Comment
        FROM ( SELECT TOP 10 Job, Saved
               FROM Tmp_JobsToDelete
               ORDER BY Job DESC ) FilterQ
        ORDER BY Job
        LIMIT 10;

        SELECT H.entry_id,
               H.posting_time,
               H.machine,
               H.processor_count_active,
               H.free_memory_mb,
               'First row to be deleted'
        FROM sw.t_machine_status_history H
             INNER JOIN ( SELECT machine,
                                 MIN(entry_id) AS Entry_ID
                          FROM sw.t_machine_status_history
                          WHERE entry_id IN
                                   ( SELECT entry_id
                                     FROM ( SELECT entry_id,
                                            Row_Number() OVER ( PARTITION BY machine ORDER BY entry_id DESC ) AS RowRank
                                            FROM sw.t_machine_status_history ) RankQ
                                     WHERE RowRank > 1000 )
                          GROUP BY machine
                        ) FilterQ
               ON H.entry_id = FilterQ.entry_id
        ORDER BY machine
    Else
        Delete From sw.t_job_steps_history
        Where job In (Select job From Tmp_JobsToDelete)

        Delete From sw.t_job_step_dependencies_history
        Where job In (Select job From Tmp_JobsToDelete)

        Delete From sw.t_job_parameters_history
        Where job In (Select job From Tmp_JobsToDelete)

        Delete From sw.t_jobs_history
        Where job In (Select job From Tmp_JobsToDelete)

        -- Keep the 1000 most recent status values for each machine
        DELETE sw.t_machine_status_history
        WHERE entry_id IN
              ( SELECT entry_id
                FROM ( SELECT entry_id,
                              Row_Number() OVER ( PARTITION BY machine ORDER BY entry_id DESC ) AS RowRank
                       FROM sw.t_machine_status_history ) RankQ

                       /********************************************************************************
                       ** This DELETE query includes the target table name in the FROM clause
                       ** The WHERE clause needs to have a self join to the target table, for example:
                       **   UPDATE sw.t_machine_status_history
                       **   SET ...
                       **   FROM source
                       **   WHERE source.id = sw.t_machine_status_history.id;
                       **
                       ** Delete queries must also include the USING keyword
                       ** Alternatively, the more standard approach is to rearrange the query to be similar to
                       **   DELETE FROM sw.t_machine_status_history WHERE id in (SELECT id from ...)
                       ********************************************************************************/

                                              ToDo: Fix this query

                WHERE RowRank > 1000 )

        -- Keep the 500 most recent processing stats values for each processor
        DELETE sw.t_job_step_processing_stats
        WHERE entry_id IN
              ( SELECT entry_id
                FROM ( SELECT entry_id,
                              processor,
                              entered,
                              job,
                              step,
                              Row_Number() OVER ( PARTITION BY processor ORDER BY entered DESC ) AS RowRank
                       FROM sw.t_job_step_processing_stats ) RankQ

                       /********************************************************************************
                       ** This DELETE query includes the target table name in the FROM clause
                       ** The WHERE clause needs to have a self join to the target table, for example:
                       **   UPDATE sw.t_job_step_processing_stats
                       **   SET ...
                       **   FROM source
                       **   WHERE source.id = sw.t_job_step_processing_stats.id;
                       **
                       ** Delete queries must also include the USING keyword
                       ** Alternatively, the more standard approach is to rearrange the query to be similar to
                       **   DELETE FROM sw.t_job_step_processing_stats WHERE id in (SELECT id from ...)
                       ********************************************************************************/

                                              ToDo: Fix this query

                WHERE RowRank > 500 )

    End If;

    If _infoOnly Then
        _message := 'Would delete ';
    Else
        _message := 'Deleted ';
    End If;

    _message := format('%s %s old jobs from the history tables; job number range %s to %s',
                        _message, _jobCountToDelete, _jobFirst, _jobLast);

    If Not _infoOnly And _jobCountToDelete > 0 Then
        Call public.post_log_entry ('Normal', _message, 'DeleteOldJobsFromHistory');
    End If;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --

    If char_length(_message) > 0 Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_JobsToDelete;
END
$$;

COMMENT ON PROCEDURE sw.delete_old_jobs_from_history IS 'DeleteOldJobsFromHistory';
