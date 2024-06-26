--
CREATE OR REPLACE PROCEDURE public.delete_old_data_experiments_jobs_and_logs
(
    _infoOnly boolean = true,
    _yearsToRetain int = 4,
    _recentJobOverrideYears real = 2,
    _logEntryMonthsToRetain int = 3,
    _datasetSkipList text = '',
    _experimentSkipList text = '',
    _deleteJobs boolean = true,
    _deleteDatasets boolean = true,
    _deleteExperiments boolean = true,
    _maxItemsToProcess int = 75000,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes old data, experiments, jobs, and log entries
**      Intended to be used with the test copies of the main databases to reduce row counts
**
**      To avoid deleting production data, this procedure includes a RETURN call prior to any delete queries
**
**  Arguments:
**    _infoOnly                 Change to false to actually perform the deletion
**    _yearsToRetain            Number of years of data to retain; setting to 4 will delete data more than 4 years old; minimum value is 1
**    _recentJobOverrideYears   Keeps datasets and experiments that have had an analysis job run within this mean years
**    _logEntryMonthsToRetain   Number of months of logs to retain
**    _datasetSkipList          List of datasets to skip
**    _experimentSkipList       List of experiments to skip
**    _message                   Status message
**    _returnCode                Return code
**
**  Auth:   mem
**  Date:   02/24/2012 mem - Initial version
**          02/28/2012 mem - Added _maxItemsToProcess
**          05/28/2015 mem - Removed T_Analysis_Job_Processor_Group_Associations, since deprecated
**          10/28/2015 mem - Added T_Prep_LC_Run_Dataset and removed T_Analysis_Job_Annotations and T_Dataset_Annotations
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/04/2017 mem - Add T_Experiment_Reference_Compounds
**          12/06/2018 mem - Call update_experiment_group_member_count to update T_Experiment_Groups
**          08/15/2022 mem - Use new column names
**          08/26/2022 mem - Use new column name in T_Log_Entries
**          07/07/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _jobCount int;
    _deleteCount int;
    _datasetCount int;
    _warningCount int;
    _warningMsg text;
    _callingProcName text;
    _currentLocation text := 'Start';
    _deleteThreshold timestamp;
    _jobKeepThreshold timestamp;
    _logDeleteThreshold timestamp;
    _maxItemsToAppend int;
    _dataset text;
    _job int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly      := Coalesce(_infoOnly, true);
    _yearsToRetain := Coalesce(_yearsToRetain, 4);

    If _yearsToRetain < 1 Then
        _yearsToRetain := 1;
    End If;

    _recentJobOverrideYears := Coalesce(_recentJobOverrideYears, 2);

    If _recentJobOverrideYears < 0.5 Then
        _recentJobOverrideYears := 0.5;
    End If;

    _logEntryMonthsToRetain := Coalesce(_logEntryMonthsToRetain, 3);

    If _logEntryMonthsToRetain < 1 Then
        _logEntryMonthsToRetain := 1;
    End If;

    _datasetSkipList    := Trim(Coalesce(_datasetSkipList, ''));
    _experimentSkipList := Trim(Coalesce(_experimentSkipList, ''));

    _deleteJobs         := Coalesce(_deleteJobs, true);
    _deleteDatasets     := Coalesce(_deleteDatasets, true);
    _deleteExperiments  := Coalesce(_deleteExperiments, true);

    _maxItemsToProcess  := Coalesce(_maxItemsToProcess, 75000);

    If _maxItemsToProcess <= 0 Then
        _maxItemsToProcess := 1000000;
    End If;

    _deleteThreshold    := CURRENT_TIMESTAMP - make_interval(years  => _yearsToRetain);
    _jobKeepThreshold   := CURRENT_TIMESTAMP - make_interval(days   => Round(_recentJobOverrideYears * 365)::int);
    _logDeleteThreshold := CURRENT_TIMESTAMP - make_interval(months => _logEntryMonthsToRetain);

    RAISE INFO 'Delete threshold:     %', _deleteThreshold;
    RAISE INFO 'Job delete threshold: %', _jobKeepThreshold;
    RAISE INFO 'Log delete threshold: %', _logDeleteThreshold;

    ---------------------------------------------------
    -- This RETURN statement skips the rest of the procedure
    -- If you really want to delete data, remove the following line
    ---------------------------------------------------

    RETURN;

    ---------------------------------------------------
    -- Create temporary tables to hold jobs, datasets, and experiments to delete
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetsToDelete (
        Dataset_ID int NOT NULL,
        Dataset text NOT NULL,
        Created timestamp NULL
    );

    CREATE INDEX IX_Tmp_DatasetsToDelete ON Tmp_DatasetsToDelete (Dataset_ID);

    CREATE TEMP TABLE Tmp_ExperimentsToDelete (
        Exp_ID int NOT NULL,
        Experiment text NOT NULL,
        EX_created timestamp NULL
    );

    CREATE INDEX IX_Tmp_ExperimentsToDelete ON Tmp_ExperimentsToDelete (Exp_ID);

    CREATE TEMP TABLE Tmp_JobsToDelete (
        Job int NOT NULL,
        Created timestamp NULL
    );

    CREATE INDEX IX_Tmp_JobsToDelete ON Tmp_JobsToDelete (Job);

    ---------------------------------------------------
    -- Find all datasets more than _deleteThreshold years old
    -- Exclude datasets with a job that was created within the last _jobKeepThreshold years
    ---------------------------------------------------

    If _deleteDatasets Then
        INSERT INTO Tmp_DatasetsToDelete (dataset_id, dataset, created)
        SELECT dataset_id,
            dataset,
            created
        FROM t_dataset
        WHERE created < _deleteThreshold AND
              NOT dataset SIMILAR TO 'DataPackage_[0-9]%' AND
              NOT dataset IN (SELECT Value
                              FROM public.parse_delimited_list ( _datasetSkipList, ',')
                             ) AND
              NOT dataset IN (SELECT DISTINCT DS.dataset
                              FROM t_dataset DS INNER JOIN
                                   t_analysis_job AJ ON DS.dataset_id = AJ.dataset_id
                              WHERE created >= _jobKeepThreshold
                             )
        ORDER BY created
        LIMIT _maxItemsToProcess;

    End If;

    ---------------------------------------------------
    -- Find Experiments to delete
    ---------------------------------------------------

    If _deleteExperiments Then
        INSERT INTO Tmp_ExperimentsToDelete (exp_id, experiment, created)
        SELECT E.exp_id,
               E.experiment,
               E.created
        FROM t_experiments E
        WHERE NOT E.experiment IN ('Placeholder', 'DMS_Pipeline_Data') AND
              E.created < _deleteThreshold AND
              NOT experiment IN (SELECT Value
                                 FROM public.parse_delimited_list ( _experimentSkipList, ',')) AND
              NOT experiment IN (SELECT E.experiment
                                 FROM t_dataset DS
                                     INNER JOIN t_experiments E
                                         ON DS.exp_id = E.exp_id
                                     LEFT OUTER JOIN Tmp_DatasetsToDelete DSDelete
                                         ON DS.dataset_id = DSDelete.dataset_id
                                 WHERE DSDelete.dataset_id IS NULL)
        GROUP BY E.exp_id,
                E.experiment,
                E.created
        ORDER BY E.created
        LIMIT _maxItemsToProcess;
    End If;

    ---------------------------------------------------
    -- Find Jobs that correspond to datasets in Tmp_DatasetsToDelete
    ---------------------------------------------------

    If _deleteJobs Then

        INSERT INTO Tmp_JobsToDelete (job, created)
        SELECT J.job,
               J.created
        FROM Tmp_DatasetsToDelete DS
            INNER JOIN t_analysis_job J
            ON DS.dataset_id = J.dataset_id
        ORDER BY J.job
        LIMIT _maxItemsToProcess;

        ---------------------------------------------------
        -- Append jobs that finished prior to _deleteThreshold
        ---------------------------------------------------

        If _maxItemsToProcess > 0 Then
            SELECT COUNT(*)
            INTO _jobCount
            FROM Tmp_JobsToDelete;

            _maxItemsToAppend := _maxItemsToProcess - _jobCount;
        Else
            _maxItemsToAppend := 1000000;
        End If;

        If _maxItemsToAppend > 0 Then
            INSERT INTO Tmp_JobsToDelete (job, created)
            SELECT job,
                   created
            FROM t_analysis_job
            WHERE Coalesce(finish, start, created) < _deleteThreshold AND
                NOT job IN (SELECT job FROM Tmp_JobsToDelete)
            ORDER BY job
            LIMIT _maxItemsToAppend;
        End If;

    End If;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        -- Preview all of the datasets and experiments that would be deleted
        SELECT Dataset_ID, Dataset AS Dataset_to_Delete, Created
        FROM Tmp_DatasetsToDelete
        ORDER BY Dataset_ID DESC;

        SELECT E.Exp_ID,
               E.Experiment AS Experiment_to_Delete,
               E.EX_Created AS Created,
               CASE
                   WHEN EG.Group_ID IS NULL THEN ''
                   ELSE format('Note: parent of experiment group %s; experiment may not get deleted', EG.Group_ID)
               END AS Note
        FROM Tmp_ExperimentsToDelete E
             LEFT OUTER JOIN t_experiment_groups EG
               ON E.Exp_ID = EG.parent_exp_id
        ORDER BY Exp_ID DESC;

        SELECT job AS Job_to_Delete,
               Tmp_JobsToDelete.created AS Created,
               T.analysis_tool AS Analysis_Tool
        FROM Tmp_JobsToDelete
             INNER JOIN t_analysis_job J
               ON Tmp_JobsToDelete.job = J.job
             INNER JOIN t_analysis_tool T
               ON J.analysis_tool_id = T.analysis_tool_id
        ORDER BY Tmp_JobsToDelete.job DESC;

        ---------------------------------------------------
        -- Count old log messages
        ---------------------------------------------------

        -- ToDo: Update this to use RAISE INFO

        SELECT 't_log_entries' AS Log_Table_Name, COUNT(*) AS Rows_to_Delete
        FROM t_log_entries
        WHERE entered < _logDeleteThreshold
        UNION
        SELECT 't_event_log' AS Log_Table_Name, COUNT(*) AS Rows_to_Delete
        FROM t_event_log
        WHERE entered < _logDeleteThreshold
        UNION
        SELECT 't_usage_log' AS Log_Table_Name, COUNT(*) AS Rows_to_Delete
        FROM t_usage_log
        WHERE posting_time < _logDeleteThreshold
        UNION
        SELECT 't_predefined_analysis_scheduling_queue' AS Log_Table_Name, COUNT(*) AS Rows_to_Delete
        FROM t_predefined_analysis_scheduling_queue
        WHERE entered < _logDeleteThreshold
        UNION
        SELECT 't_analysis_job_status_history' AS Log_Table_Name, COUNT(*) AS Rows_to_Delete
        FROM t_analysis_job_status_history
        WHERE posting_time < _logDeleteThreshold;

        RETURN;
    End IF;

    ---------------------------------------------------
    -- Delete jobs and related data
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _jobCount
    FROM Tmp_JobsToDelete;

    If _jobCount > 0 And _deleteJobs Then
    -- <a>
        _message := format('Deleted %s %s from:', _jobCount, public.check_plural(_jobCount, 'job', 'jobs'));

        BEGIN

            /*
                ---------------------------------------------------
                -- Deprecated in Summer 2015:

                _currentLocation := 'DELETE t_analysis_job_annotations';

                DELETE FROM t_analysis_job_annotations target
                WHERE EXISTS (SELECT j.job FROM Tmp_JobsToDelete J WHERE target.job = J.job);

                _message := format('%sT_Analysis_Job_Annotations, ', _message);
            */

            /*
                ---------------------------------------------------
                -- Deprecated in May 2015:

                _currentLocation := 'DELETE t_analysis_job_processor_group_associations';

                DELETE FROM t_analysis_job_processor_group_associations target
                WHERE EXISTS (SELECT j.job FROM Tmp_JobsToDelete J WHERE target.job = J.job);

                _message := format('%st_analysis_job_processor_group_associations, ', _message);
            */

            _currentLocation := 'DELETE t_analysis_job_psm_stats';

            DELETE FROM t_analysis_job_psm_stats target
            WHERE EXISTS (SELECT J.Job FROM Tmp_JobsToDelete J WHERE target.job = J.job);

            _message := format('%s t_analysis_job_psm_stats', _message);

            -- Disable the trigger that prevents all rows from being deleted
            ALTER TABLE t_analysis_job DISABLE TRIGGER trig_t_analysis_job_after_delete_all

            _currentLocation := 'DELETE t_analysis_job';

            DELETE FROM t_analysis_job target
            WHERE EXISTS (SELECT J.Job FROM Tmp_JobsToDelete J WHERE target.job = J.job);

            _message := format('%s and t_analysis_job', _message);

            CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');

            ALTER TABLE t_analysis_job ENABLE TRIGGER trig_t_analysis_job_after_delete_all

            -- Delete orphaned entries in t_analysis_job_batches that are older than _deleteThreshold

            -- The following index helps to speed this delete
            --
            -- If Not Exists (SELECT * FROM sys.indexes WHERE NAME = 'IX_Tmp_T_Analysis_Job_Batch_ID_Include_Job') Then
            --     _currentLocation := 'CREATE Index IX_Tmp_T_Analysis_Job_Batch_ID_Include_Job';
            --     CREATE INDEX IX_Tmp_T_Analysis_Job_Batch_ID_Include_Job
            --     ON t_analysis_job (batch_id)
            --     INCLUDE (job)
            -- End If;

            _currentLocation := 'DELETE t_analysis_job_batches';

            DELETE FROM t_analysis_job_batches AJB
            WHERE AJB.Batch_Created < _deleteThreshold AND
                  NOT EXISTS (SELECT AJ.job FROM t_analysis_job AJ WHERE AJB.batch_id = AJ.batch_id);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                _message := format('Deleted %s %s from t_analysis_job_batches since orphaned and older than %s',
                                    _deleteCount, public.check_plural(_deleteCount, 'entry', 'entries'), _deleteThreshold);

                CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');
            End If;

            -- _currentLocation := 'DROP Index IX_Tmp_T_Analysis_Job_Batch_ID_Include_Job';
            -- DROP INDEX IX_Tmp_T_Analysis_Job_Batch_ID_Include_Job ON t_analysis_job

            -- Delete orphaned entries in t_analysis_job_request that are older than _deleteThreshold

            _currentLocation := 'DELETE t_analysis_job_request';

            DELETE FROM t_analysis_job_request
            WHERE request_id IN (SELECT AJR.request_id
                                 FROM t_analysis_job_request AJR
                                      LEFT OUTER JOIN t_analysis_job AJ
                                        ON AJR.request_id = AJ.request_id
                                 WHERE AJ.request_id IS NULL AND AJR.created < _deleteThreshold
                                );
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                 _message := format('Deleted %s %s from t_analysis_job_request since orphaned and older than %s',
                                    _deleteCount, public.check_plural(_deleteCount, 'entry', 'entries'), _deleteThreshold);

                CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');
            End If;

            -- Delete orphaned entries in t_analysis_job_id that are older than _logDeleteThreshold

            _currentLocation := 'DELETE t_analysis_job_id';

            DELETE FROM t_analysis_job_id target
            WHERE NOT target.Note LIKE '%broker%' AND
                  target.created < _logDeleteThreshold AND
                  NOT EXISTS (SELECT J.job FROM t_analysis_job J WHERE target.job = J.job);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                _message := format('Deleted %s %s from t_analysis_job_id since orphaned and older than %s',
                                    _deleteCount, public.check_plural(_deleteCount, 'entry', 'entries'), _deleteThreshold);

                CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');
            End If;

        EXCEPTION
            WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS
                    _sqlState         = returned_sqlstate,
                    _exceptionMessage = message_text,
                    _exceptionDetail  = pg_exception_detail,
                    _exceptionContext = pg_exception_context;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => _currentLocation, _logError => true);

            If Coalesce(_returnCode, '') = '' Then
                _returnCode := _sqlState;
            End If;

            _message := format('Exception deleting jobs: %s', _message);
            RAISE INFO '%', _message;

            DROP TABLE IF EXISTS Tmp_DatasetsToDelete;
            DROP TABLE IF EXISTS Tmp_ExperimentsToDelete;
            DROP TABLE IF EXISTS Tmp_JobsToDelete;

            RETURN;
        END;

        COMMIT;
    End; -- </a>

    ---------------------------------------------------
    -- Deleted datasets and related data
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _deleteCount
    FROM Tmp_DatasetsToDelete;

    If _deleteCount > 0 And _deleteDatasets Then
    -- <b>
        _message := format('Deleted %s datasets from:', _deleteCount);

        BEGIN

            -- Make sure no jobs are defined for any of these datasets
            -- Abort if there are
            If Exists (SELECT * FROM t_analysis_job J INNER JOIN Tmp_DatasetsToDelete D ON J.dataset_id = D.dataset_id) Then
                _message := 'Cannot delete dataset since job exists';

                _warningCount := 0;

                FOR _dataset, _job IN
                    SELECT d.dataset,
                           j.job
                    FROM t_analysis_job J
                         INNER JOIN Tmp_DatasetsToDelete D
                           ON J.dataset_id = D.dataset_id
                    ORDER BY d.dataset, j.job
                LOOP
                    RAISE WARNING 'Cannot delete dataset % since job % exists', _dataset, _job;

                    _warningCount := _warningCount + 1;

                    If _warningCount > 10 Then
                        -- Break out of the for loop
                        EXIT;
                    End If;

                END LOOP;

                If _warningCount > 10 Then

                    SELECT COUNT(DISTINCT d.dataset)
                    INTO _datasetCount
                    FROM t_analysis_job J
                         INNER JOIN Tmp_DatasetsToDelete D
                           ON J.dataset_id = D.dataset_id;

                    If _datasetCount > 1 Then
                        _warningMsg := format('%s datasets have jobs and thus cannot be deleted', _deleteCount);
                        RAISE WARNING '%', _warningMsg;

                        _message := format('%s; %s', _message, _warningMsg);
                    End If
                End If;

                DROP TABLE IF EXISTS Tmp_DatasetsToDelete;
                DROP TABLE IF EXISTS Tmp_ExperimentsToDelete;
                DROP TABLE IF EXISTS Tmp_JobsToDelete;

                RETURN;
            End If;

            _currentLocation := 'DELETE t_dataset_qc';

            DELETE FROM t_dataset_qc target
            WHERE EXISTS (SELECT DS.dataset_id FROM Tmp_DatasetsToDelete DS WHERE target.dataset_id = DS.dataset_id);

            _message := format('%s t_dataset_qc,', _message);

            /*
                ---------------------------------------------------
                -- Deprecated in Summer 2015:
                _currentLocation := 'DELETE t_dataset_annotations';

                DELETE FROM t_dataset_annotations target
                WHERE EXISTS (SELECT DS.dataset_id FROM Tmp_DatasetsToDelete DS WHERE target.dataset_id = DS.dataset_id);

                _message := format('%sT_Dataset_Annotations, ', _message);
            */

            _currentLocation := 'DELETE t_dataset_archive';

            DELETE FROM t_dataset_archive target
            WHERE EXISTS (SELECT DS.dataset_id FROM Tmp_DatasetsToDelete DS WHERE target.dataset_id = DS.dataset_id);

            _message := format('%s t_dataset_archive,', _message);

            _currentLocation := 'DELETE t_dataset_info';

            DELETE FROM t_dataset_info target
            WHERE EXISTS (SELECT DS.dataset_id FROM Tmp_DatasetsToDelete DS WHERE target.dataset_id = DS.dataset_id);

            _message := format('%s t_dataset_info,', _message);

            _currentLocation := 'DELETE t_dataset_storage_move_log';

            DELETE FROM t_dataset_storage_move_log target
            WHERE EXISTS (SELECT DS.dataset_id FROM Tmp_DatasetsToDelete DS WHERE target.dataset_id = DS.dataset_id);

            _message := format('%s t_dataset_storage_move_log,', _message);

            _currentLocation := 'DELETE t_requested_run';

            DELETE FROM t_requested_run target
            WHERE EXISTS (SELECT DS.dataset_id FROM Tmp_DatasetsToDelete DS WHERE target.dataset_id = DS.dataset_id);

            _message := format('%s t_requested_run,', _message);

            _currentLocation := 'DELETE t_prep_lc_run_dataset';

            DELETE FROM t_prep_lc_run_dataset target
            WHERE EXISTS (SELECT DS.dataset_id FROM Tmp_DatasetsToDelete DS WHERE target.dataset_id = DS.dataset_id);

            _message := format('%s t_prep_lc_run_dataset,', _message);

            _currentLocation := 'DELETE t_dataset';

            DELETE FROM t_dataset target
            WHERE EXISTS (SELECT DS.dataset_id FROM Tmp_DatasetsToDelete DS WHERE target.dataset_id = DS.dataset_id);

            _message := format('%s and t_dataset', _message);

            CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');

            -- Delete orphaned entries in t_requested_run that are older than _deleteThreshold

            DELETE FROM t_requested_run target
            WHERE target.Created < _deleteThreshold AND
                  target.DatasetID IS NULL;
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                _message := format('Deleted %s %s from t_requested_run since orphaned and older than %s',
                                    _deleteCount, public.check_plural(_deleteCount, 'entry', 'entries'), _deleteThreshold);

                CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');
            End If;

            -- Delete orphaned entries in t_requested_run_batches that are older than _deleteThreshold

            DELETE FROM t_requested_run_batches target
            WHERE target.created < _deleteThreshold AND
                  NOT EXISTS (SELECT RR.batch_ID FROM t_requested_run RR WHERE target.batch_id = RR.batch_id);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                _message := format('Deleted %s %s from t_requested_run_batches since orphaned and older than %s',
                                    _deleteCount, public.check_plural(_deleteCount, 'entry', 'entries'), _deleteThreshold);

                CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');
            End If;

            -- Delete orphaned entries in t_dataset_scan_types

            DELETE FROM t_dataset_scan_types target
            WHERE NOT EXISTS (SELECT DS.dataset_ID FROM t_dataset DS WHERE target.dataset_id = DS.dataset_id);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                _message := format('Deleted %s %s from t_dataset_scan_types since orphaned',
                                    _deleteCount, public.check_plural(_deleteCount, 'entry', 'entries'));

                CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');
            End If;

        EXCEPTION
            WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS
                    _sqlState         = returned_sqlstate,
                    _exceptionMessage = message_text,
                    _exceptionDetail  = pg_exception_detail,
                    _exceptionContext = pg_exception_context;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => _currentLocation, _logError => true);

            If Coalesce(_returnCode, '') = '' Then
                _returnCode := _sqlState;
            End If;

            _message := format('Exception deleting datasets: %s', _message);
            RAISE INFO '%', _message;

            DROP TABLE IF EXISTS Tmp_DatasetsToDelete;
            DROP TABLE IF EXISTS Tmp_ExperimentsToDelete;
            DROP TABLE IF EXISTS Tmp_JobsToDelete;

            RETURN;
        END;

        COMMIT;
    End; -- </b>

    ---------------------------------------------------
    -- Delete experiments and related data
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _deleteCount
    FROM Tmp_ExperimentsToDelete;

    If _deleteCount > 0 And _deleteDatasets And _deleteExperiments Then
    -- <c>
        _message := format('Deleted %s experiments from:', _deleteCount);

        BEGIN

            -- Delete experiments in Tmp_ExperimentsToDelete that are still in t_requested_run
            DELETE FROM Tmp_ExperimentsToDelete target
            WHERE EXISTS (SELECT RR.exp_id FROM t_requested_run RR WHERE target.exp_id = RR.exp_id);

            _currentLocation := 'DELETE t_experiment_biomaterial';

            DELETE FROM t_experiment_biomaterial target
            WHERE EXISTS (SELECT E.exp_id FROM Tmp_ExperimentsToDelete E WHERE target.exp_id = E.exp_id);

            _message := format('%s t_experiment_biomaterial,', _message);

            _currentLocation := 'DELETE t_experiment_group_members';

            DELETE FROM t_experiment_group_members target
            WHERE EXISTS (SELECT E.exp_id FROM Tmp_ExperimentsToDelete E WHERE target.exp_id = E.exp_id);

            _message := format('%s t_experiment_group_members,', _message);

            _currentLocation := 'DELETE t_experiment_groups';

            DELETE FROM t_experiment_groups target
            WHERE EXISTS (SELECT E.exp_id FROM Tmp_ExperimentsToDelete E WHERE target.parent_exp_id = E.exp_id) AND
                  NOT EXISTS (SELECT EGM.group_id FROM t_experiment_group_members EGM WHERE target.group_id = EGM.group_id);

            _message := format('%s t_experiment_groups,', _message);

            _currentLocation := 'DELETE t_experiment_reference_compounds';

            DELETE FROM t_experiment_reference_compounds target
            WHERE EXISTS (SELECT E.exp_id FROM Tmp_ExperimentsToDelete E WHERE target.exp_id = E.exp_id);

            _message := format('%s t_experiment_biomaterial,', _message);

            _currentLocation := 'DELETE t_experiments';

            DELETE FROM t_experiments target
            WHERE EXISTS (SELECT E.exp_id FROM Tmp_ExperimentsToDelete E WHERE target.exp_id = E.exp_id) AND
                  NOT EXISTS (SELECT EG.parent_exp_id FROM t_experiment_groups EG WHERE target.exp_id = EG.parent_exp_id);

            _message := format('%s and t_experiments', _message);

            CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');

            -- Delete orphaned entries in t_experiment_groups

            DELETE FROM t_experiment_groups target
            WHERE target.EG_Created < _deleteThreshold AND
                  NOT EXISTS (SELECT EGM.group_id FROM t_experiment_group_members EGM WHERE target.group_id = EGM.group_id)
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                _message := format('Deleted %s %s from t_experiment_groups since orphaned and older than %s',
                                    _deleteCount, public.check_plural(_deleteCount, 'entry', 'entries'), _deleteThreshold);

                CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');
            End If;

            -- Assure that member_count is accurate in t_experiment_groups
            CALL update_experiment_group_member_count (_groupID => 0);

        EXCEPTION
            WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS
                    _sqlState         = returned_sqlstate,
                    _exceptionMessage = message_text,
                    _exceptionDetail  = pg_exception_detail,
                    _exceptionContext = pg_exception_context;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => _currentLocation, _logError => true);

            If Coalesce(_returnCode, '') = '' Then
                _returnCode := _sqlState;
            End If;

            _message := format('Exception deleting experiments: %s', _message);
            RAISE INFO '%', _message;

            DROP TABLE IF EXISTS Tmp_DatasetsToDelete;
            DROP TABLE IF EXISTS Tmp_ExperimentsToDelete;
            DROP TABLE IF EXISTS Tmp_JobsToDelete;

            RETURN;
        END;

        COMMIT;
    End; -- </c>

    ---------------------------------------------------
    -- Delete orphaned Aux_Info entries
    ---------------------------------------------------

    -- Experiments (Target_Type_ID = 500)

    DELETE FROM t_aux_info_value
    WHERE entry_id IN (
        SELECT AIVal.entry_ID
        FROM t_aux_info_category AIC
             INNER JOIN t_aux_info_subcategory Subcat
               ON AIC.aux_category_id = Subcat.aux_category_id
             INNER JOIN t_aux_info_description Descrip
               ON Subcat.aux_subcategory_id = Descrip.aux_subcategory_id
             INNER JOIN t_aux_info_value AIVal
               ON Descrip.aux_description_id = AIVal.aux_description_id
             LEFT OUTER JOIN t_experiments E
               ON AIVal.target_id = E.exp_id
        WHERE AIC.target_type_id = 500 AND
              E.experiment IS NULL AND
              AIVal.target_id > 0
        );
    --
    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _deleteCount > 0 Then
        _message := format('Deleted %s experiment related %s from t_aux_info_value since orphaned',
                            _deleteCount, public.check_plural(_deleteCount, 'entry', 'entries'));

        CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');
    End If;

    -- Biomaterial (Target_Type_ID = 501)

    DELETE FROM t_aux_info_value
    WHERE entry_id IN (
        SELECT AIVal.entry_id
        FROM t_aux_info_category AIC
             INNER JOIN t_aux_info_subcategory Subcat
               ON AIC.aux_category_id = Subcat.aux_category_id
             INNER JOIN t_aux_info_description Descrip
               ON Subcat.aux_subcategory_id = Descrip.aux_subcategory_id
             INNER JOIN t_aux_info_value AIVal
               ON Descrip.aux_description_id = AIVal.aux_description_id
             LEFT OUTER JOIN t_biomaterial
               ON AIVal.target_id = t_biomaterial.biomaterial_id
        WHERE AIC.target_type_id = 501 AND
              AIVal.target_id > 0 AND
              t_biomaterial.biomaterial_id IS NULL
        );
    --
    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _deleteCount > 0 Then
        _message := format('Deleted %s biomaterial related %s from t_aux_info_value since orphaned',
                            _deleteCount, public.check_plural(_deleteCount, 'entry', 'entries'));

        CALL post_log_entry ('Normal', _message, 'Delete_Old_Data_Experiments_Jobs_And_Logs');
    End If;

    -- Datasets (Target_Type_ID = 502)
    -- Note that although DMS supports Aux_Info for datasets, it has never been used
    -- Thus, we'll skip this query

    -- DELETE FROM t_aux_info_value
    -- WHERE entry_id IN (
    --     SELECT AIVal.entry_id
    --     FROM t_aux_info_category AIC
    --          INNER JOIN t_aux_info_subcategory Subcat
    --            ON AIC.aux_category_id = Subcat.aux_category_id
    --          INNER JOIN t_aux_info_description Descrip
    --          ON Subcat.aux_subcategory_id = Descrip.aux_subcategory_id
    --          INNER JOIN t_aux_info_value AIVal
    --            ON Descrip.aux_description_id = AIVal.aux_description_id
    --          LEFT OUTER JOIN t_dataset
    --            ON AIVal.target_id = t_dataset.dataset_id
    --     WHERE AIC.target_type_id = 502 AND
    --           AIVal.target_id > 0 AND
    --           t_dataset.dataset_id IS NULL
    --     );

    ---------------------------------------------------
    -- Delete old entries in various tables
    ---------------------------------------------------

    DELETE FROM t_predefined_analysis_scheduling_queue
    WHERE entered < _logDeleteThreshold;

    DELETE FROM t_analysis_job_status_history
    WHERE posting_time < _logDeleteThreshold;

    ---------------------------------------------------
    -- Delete old log messages
    ---------------------------------------------------

    DELETE FROM t_log_entries
    WHERE Entered < _logDeleteThreshold;

    DELETE FROM t_event_log
    WHERE entered < _logDeleteThreshold;

    DELETE FROM t_usage_log
    WHERE posting_time < _logDeleteThreshold;

    DROP TABLE Tmp_DatasetsToDelete;
    DROP TABLE Tmp_ExperimentsToDelete;
    DROP TABLE Tmp_JobsToDelete;
END
$$;

COMMENT ON PROCEDURE public.delete_old_data_experiments_jobs_and_logs IS 'DeleteOldDataExperimentsJobsAndLogs';
