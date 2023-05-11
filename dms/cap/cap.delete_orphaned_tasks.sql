--
-- Name: delete_orphaned_tasks(boolean, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.delete_orphaned_tasks(IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete capture task jobs with state = 0 where the dataset no longer exists in DMS
**
**  Auth:   mem
**  Date:   05/22/2019 mem - Initial version
**          10/11/2022 mem - Ported to PostgreSQL
**          02/02/2023 mem - Update table aliases
**          04/02/2023 mem - Rename procedure and functions
**          04/27/2023 mem - Use boolean for data type name
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**
*****************************************************/
DECLARE
    _formatSpecifier text := '%-15s %-10s %-15s %-10s %-15s %-20s %-10s %-50s %-20s';
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _previewData record;

    _jobCount int;
    _job int;
    _dataset text;
    _datasetId int;
    _scriptName text;
    _logMessage text;
    _jobsDeleted int;
BEGIN
    _infoOnly := Coalesce(_infoOnly, true);
    _message := '';

    If _infoOnly Then
        RAISE INFO ' ';
    End If;

    ---------------------------------------------------
    -- Find orphaned capture task jobs
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_JobsToDelete (
        Job int Not Null,
        HasDependencies boolean Not null
    );

    CREATE INDEX IX_Tmp_JobsToDelete_Job On Tmp_JobsToDelete (Job);

    INSERT INTO Tmp_JobsToDelete ( Job, HasDependencies )
    SELECT T.Job, false
    FROM cap.t_tasks T
         LEFT OUTER JOIN public.T_Dataset DS
           ON T.Dataset_ID = DS.Dataset_ID
    WHERE T.State = 0 AND
          T.Imported < CURRENT_TIMESTAMP - Interval '5 days' AND
          DS.Dataset_ID IS NULL;
    --
    GET DIAGNOSTICS _jobCount = ROW_COUNT;

    If _jobCount = 0 Then
        _message := 'Did not find any orphaned capture task jobs in cap.t_tasks';

        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        DROP TABLE Tmp_JobsToDelete;
        RETURN;
    End If;

    _message := format('Found %s orphaned capture task %s in cap.t_tasks',
                        _jobCount,
                        public.check_plural(_jobCount, 'job', 'jobs'));

    If _infoOnly Then
        RAISE INFO '%', _message;
    End If;

    ---------------------------------------------------
    -- Remove any capture task jobs that have data in t_task_steps, t_task_step_dependencies, or t_task_parameters
    ---------------------------------------------------

    UPDATE Tmp_JobsToDelete Target
    SET HasDependencies = true
    FROM cap.t_task_steps TS
    WHERE Target.Job = TS.Job;

    UPDATE Tmp_JobsToDelete Target
    SET HasDependencies = true
    FROM cap.t_task_step_dependencies TSD
    WHERE Target.Job = TSD.Job;

    UPDATE Tmp_JobsToDelete Target
    SET HasDependencies = true
    FROM cap.t_task_parameters P
    WHERE Target.Job = P.Job;

    If _infoOnly Then
        ---------------------------------------------------
        -- Preview the capture task jobs that would be deleted
        ---------------------------------------------------
        --
        RAISE INFO ' ';

        _infoHead := format(_formatSpecifier,
                            'HasDependencies',
                            'Job',
                            'Script',
                            'State',
                            'State_Name',
                            'Imported',
                            'Dataset_ID',
                            'Dataset',
                            'Instrument'
                        );

        _infoHeadSeparator := format(_formatSpecifier,
                             '---------------',
                             '----------',
                             '---------------',
                             '----------',
                             '---------------',
                             '--------------------',
                             '----------',
                             '--------------------------------------------------',
                             '------------------------------'
                        );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT D.HasDependencies,
                   T.job, T.script, T.state, T.state_name,
                   timestamp_text(T.imported) as imported, T.dataset_id, T.dataset, T.instrument
            FROM cap.V_Tasks T
                 INNER JOIN Tmp_JobsToDelete D
                   ON T.Job = D.Job
            ORDER BY T.Job
        LOOP
            _infoData := format(_formatSpecifier,
                                    CASE WHEN _previewData.hasDependencies THEN 'Yes' ELSE 'No' End,
                                    _previewData.job,
                                    _previewData.script,
                                    _previewData.state,
                                    _previewData.state_name,
                                    _previewData.imported,
                                    _previewData.dataset_id,
                                    _previewData.dataset,
                                    _previewData.instrument
                            );

            RAISE INFO '%', _infoData;

        END LOOP;

    Else
        ---------------------------------------------------
        -- Delete each capture task job individually (so that we can log the dataset name and ID in cap.t_log_entries)
        ---------------------------------------------------
        --
        _jobsDeleted := 0;

        FOR _job IN
            SELECT Job
            FROM Tmp_JobsToDelete
            WHERE Not HasDependencies
            ORDER BY Job
        LOOP
            SELECT Dataset,
                   Dataset_ID,
                   Script
            INTO _dataset, _datasetId, _scriptName
            FROM cap.t_tasks
            WHERE Job = _job;

            DELETE FROM cap.t_tasks
            WHERE Job = _job;

            _logMessage := format('Deleted orphaned %s capture task job %s for dataset %s since no longer defined in DMS',
                                    _scriptName, _job, _dataset);

            Call public.post_log_entry ('Normal', _logMessage, 'Delete_Orphaned_Tasks', 'cap');

            _jobsDeleted := _jobsDeleted + 1;
        END LOOP;

        If _jobsDeleted > 0 Then
            _message := format('Deleted %s orphaned capture task %s', _jobsDeleted, public.check_plural(_jobsDeleted, 'job', 'jobs'));
        Else
            _message := format('%s; not deleted since %s dependencies (rows in cap.t_task_steps, cap.t_task_step_dependencies, or cap.t_task_parameters)',
                                _message, public.check_plural(_jobCount, 'it has', 'they have'));
        End If;

        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_JobsToDelete;
END
$$;


ALTER PROCEDURE cap.delete_orphaned_tasks(IN _infoonly boolean, INOUT _message text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_orphaned_tasks(IN _infoonly boolean, INOUT _message text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.delete_orphaned_tasks(IN _infoonly boolean, INOUT _message text) IS 'DeleteOrphanedJobs';

