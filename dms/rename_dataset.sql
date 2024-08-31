--
-- Name: rename_dataset(text, text, integer, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.rename_dataset(IN _datasetnameold text DEFAULT ''::text, IN _datasetnamenew text DEFAULT ''::text, IN _newrequestedrunid integer DEFAULT 0, IN _infoonly boolean DEFAULT true, IN _showrequestedrunsbyexperiment boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Rename a dataset in t_dataset
**
**      Also update associated jobs in cap.t_tasks and sw.t_jobs, and updates dpkg.t_data_package_datasets
**
**  Arguments:
**    _datasetNameOld                   Dataset name to change
**    _datasetNameNew                   New dataset name
**    _newRequestedRunID                New requested run ID; -1 to leave unchanged
**    _infoOnly                         When true, preview updates
**    _showRequestedRunsByExperiment    When true, show requested runs with an experiment name that starts with the experiment name associated with the dataset
**                                      Set this to false if renaming a large number of datasets but not changing the request ID, since request name lookups can be slow
**    _message                          Status message
**    _returnCode                       Return code
**
**  Auth:   mem
**  Date:   01/25/2013 mem - Initial version
**          07/08/2016 mem - Now show old/new names and jobs even when _infoOnly is false
**          12/06/2016 mem - Include file rename statements
**          03/06/2017 mem - Validate that _datasetNameNew is no more than 80 characters long
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/03/2018 mem - Rename files in T_Dataset_Files
**                         - Update commands for renaming the dataset directory and dataset file
**          08/06/2018 mem - Fix where clause when querying V_Analysis_Job_Export
**                         - Look for requested runs that may need to be updated
**          01/04/2019 mem - Add sed command for updating the index.html file in the QC directory
**          01/20/2020 mem - Show the File_Hash in T_Dataset_Files when previewing updates
**                         - Add commands for updating the DatasetInfo.xml file with sed
**                         - Switch from Folder to Directory when calling add_update_task_parameter
**          02/19/2021 mem - Validate the characters in the new dataset name
**          11/04/2021 mem - Add more MASIC file names and use sed to edit MASIC's index.html file
**          11/05/2021 mem - Add more MASIC file names and rename files in any MzRefinery directories
**          07/21/2022 mem - Move misplaced 'cd ..' and add missing 'rem'
**          10/10/2022 mem - Add _newRequestedRunID; if defined (and active), associate the dataset with this Request ID and use it to update the dataset's experiment
**          03/04/2023 mem - Use new T_Task tables
**          03/29/2023 mem - No longer add job parameter DatasetNum
**          04/01/2023 mem - Use new DMS_Capture procedures and function names
**          04/25/2023 mem - Update Queue_State for the old and new requested runs
**          08/07/2023 mem - Show a custom error message if the dataset does not exist in T_Requested_Run
**          09/26/2023 mem - Update cached dataset names in T_Data_Package_Datasets
**          02/18/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**          08/30/2024 mem - Pass a single backslash to Position()
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetID int;
    _experiment text;
    _datasetAlreadyRenamed boolean;
    _datasetFolderPath text;
    _storageServerSharePath text;
    _lastSlashReverseText int;
    _newExperimentID int;
    _newExperiment text;
    _requestedRunInfo record;
    _requestedRunState text;
    _datasetInfo record;
    _suffixID int;
    _fileSuffix text;
    _continue boolean;
    _job int;
    _toolBaseName citext;
    _resultsFolder citext;
    _mzRefineryOutputFolder text;
    _badCh text;
    _jobFileUpdateCount int;
    _datasetInfoFile text;
    _msg text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
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

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------

    _datasetNameOld                := Trim(Coalesce(_datasetNameOld, ''));
    _datasetNameNew                := Trim(Coalesce(_datasetNameNew, ''));
    _newRequestedRunID             := Coalesce(_newRequestedRunID, 0);
    _infoOnly                      := Coalesce(_infoOnly, false);
    _showRequestedRunsByExperiment := Coalesce(_showRequestedRunsByExperiment, true);

    If _datasetNameOld = '' Then
        _message := 'Old dataset name was not specified; unable to continue';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _datasetNameNew = '' Then
        _message := 'New dataset name was not specified; unable to continue';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If char_length(_datasetNameNew) > 80 Then
        _message := 'New dataset name cannot be more than 80 characters in length';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    _badCh := public.validate_chars(_datasetNameNew, '');

    If _badCh <> '' Then
        If _badCh = '[space]' Then
            _message := 'New dataset name may not contain spaces';
        ElsIf char_length(_badCh) = 1 Then
            _message := format('New dataset name may not contain the character %s', _badCh);
        Else
            _message := format('New dataset name may not contain the characters %s', _badCh);
        End If;

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    --------------------------------------------
    -- Lookup the dataset ID
    --------------------------------------------

    _datasetAlreadyRenamed := false;

    SELECT dataset_id,
           exp_id
    INTO _datasetID, _newExperimentID
    FROM t_dataset
    WHERE dataset = _datasetNameOld::citext;

    If Not FOUND Then
        -- Old dataset name not found; perhaps it was already renamed in t_dataset
        SELECT dataset_id,
               exp_id
        INTO _datasetID, _newExperimentID
        FROM t_dataset
        WHERE dataset = _datasetNameNew::citext;

        If FOUND Then
            -- Lookup the experiment for this dataset (using the new name)
            SELECT E.experiment
            INTO _experiment
            FROM t_dataset ds
                 INNER JOIN t_experiments E
                   ON DS.exp_id = E.exp_id
            WHERE DS.dataset = _datasetNameNew::citext;

            _datasetAlreadyRenamed := true;
        End If;
    Else

        -- Old dataset name found; make sure the new name is not already in use
        If Exists (SELECT dataset_id FROM t_dataset WHERE dataset = _datasetNameNew::citext) Then
            _message := format('New dataset name already exists; unable to rename %s to %s', _datasetNameOld, _datasetNameNew);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        -- Lookup the experiment for this dataset (using the old name)
        SELECT E.experiment
        INTO _experiment
        FROM t_dataset ds
             INNER JOIN t_experiments E
               ON DS.exp_id = E.exp_id
        WHERE DS.dataset = _datasetNameOld::citext;
    End If;

    If _datasetID = 0 Then
        _message := format('Dataset not found using either the old name or the new name (%s or %s)', _datasetNameOld, _datasetNameNew);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _newRequestedRunID = 0 Then
        _message := 'Specify the new requested run ID using _newRequestedRunID (must be active); use -1 to leave the requested run ID unchanged';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _newRequestedRunID > 0 Then
        -- Lookup the experiment associated with the new requested run
        -- Additionally, verify that the requested run is active (if _datasetAlreadyRenamed = false)

        SELECT exp_id,
               state_name
        INTO _newExperimentID, _requestedRunState
        FROM t_requested_run
        WHERE request_id = _newRequestedRunID;

        If Not FOUND Then
            _message := format('Requested run request_id not found in t_requested_run: %s', _newRequestedRunID);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If Not _datasetAlreadyRenamed And _requestedRunState <> 'Active' Then
            _message := format('New requested run is not active: %s', _newRequestedRunID);
            RAISE WARNING '%', _message;
            RETURN;
        End If;
    End If;

    -- Lookup the share folder for this dataset
    SELECT Dataset_Folder_Path
    INTO _datasetFolderPath
    FROM V_Dataset_Folder_Paths
    WHERE Dataset_ID = _datasetID;

    -- Extract the parent directory path from _datasetFolderPath
    _lastSlashReverseText := Position('\' In Reverse(_datasetFolderPath));
    _storageServerSharePath := Substring(_datasetFolderPath, 1, char_length(_datasetFolderPath) - _lastSlashReverseText);

    -- Lookup acquisition metadata stored in t_requested_run
    SELECT request_id AS OldRequestedRunID,
           request_run_start AS RunStart,
           request_run_finish AS RunFinish,
           cart_id AS CartId,
           cart_config_id AS CartConfigID,
           cart_column AS CartColumn
    INTO _requestedRunInfo
    FROM t_requested_run
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        If _newRequestedRunID > 0 Then
            _message := format('Dataset ID not found in t_requested_run: %s; cannot rename the dataset', _datasetID);
            RAISE WARNING '%', _message;
            RETURN;
        Else
            _message := format('Dataset ID not found in t_requested_run: %s; it needs to be manually associated with a Requested Run', _datasetID);
            RAISE INFO '%', _message;
        End If;
    End If;

    -- Lookup the experiment name for _newExperimentID
    SELECT experiment
    INTO _newExperiment
    FROM t_experiments
    WHERE exp_id = _newExperimentID;

    If Not _infoOnly Then
        --------------------------------------------
        -- Rename the dataset in t_dataset
        --------------------------------------------

        If _datasetAlreadyRenamed Then
            _message := format('Dataset ID %s has already been renamed', _datasetID);
        ElsIf Not Exists (SELECT dataset_id FROM t_dataset WHERE dataset = _datasetNameNew::citext) Then
            -- Show the old and new values

            SELECT DS.Dataset AS Dataset_Name_Old,
                   _datasetNameNew AS Dataset_Name_New,
                   DS.Dataset_ID,
                   DS.Created AS Dataset_Created,
                   CASE WHEN DS.Exp_ID = _newExperimentID
                        THEN format('%s (Unchanged)', DS.Exp_ID)
                        ELSE format('%s -> %s', DS.Exp_ID, _newExperimentID)
                   END AS Experiment_ID,
                   CASE WHEN E.Experiment = _newExperiment
                        THEN format('%s (Unchanged)', E.Experiment)
                        ELSE format('%s -> %s', E.Experiment, _newExperiment)
                   END AS Experiment
            INTO _datasetInfo
            FROM t_dataset DS
                 INNER JOIN t_experiments AS E
                   ON DS.exp_id = E.exp_id
            WHERE DS.dataset IN (_datasetNameOld::citext, _datasetNameNew::citext);

            RAISE INFO '';
            RAISE INFO 'Renaming Dataset ID % (created %)', _datasetInfo.Dataset_ID, public.timestamp_text(_datasetInfo.Dataset_Created);
            RAISE INFO 'Old name: %', _datasetInfo.Dataset_Name_Old;
            RAISE INFO 'New name: %', _datasetInfo.Dataset_Name_New;
            RAISE INFO 'Experiment ID:   %', _datasetInfo.Experiment_ID;
            RAISE INFO 'Experiment Name: %', _datasetInfo.Experiment;

            -- Rename the dataset and update the experiment ID (if changed)
            UPDATE t_dataset
            SET dataset = _datasetNameNew,
                folder_name = _datasetNameNew,
                exp_id = _newExperimentID
            WHERE dataset_id = _datasetID AND
                  dataset = _datasetNameOld::citext;

            _message := format('Renamed dataset ID %s from "%s" to "%s"', _datasetID, _datasetNameOld, _datasetNameNew);
            RAISE INFO '%', _message;

            CALL post_log_entry ('Normal', _message, 'Rename_Dataset');
        End If;

        -- Rename any files in t_dataset_files
        If Exists (SELECT dataset_id FROM t_dataset_files WHERE dataset_id = _datasetID) Then
            UPDATE t_dataset_files
            SET file_path = Replace(file_path, _datasetNameOld::citext, _datasetNameNew::citext)
            WHERE Dataset_ID = _datasetID;
        End If;

    Else
        --------------------------------------------
        -- Preview the changes (or show the dataset info if already renamed)
        --------------------------------------------

        If Exists (SELECT dataset_id FROM t_dataset WHERE dataset = _datasetNameNew::citext) Then
            SELECT 'The dataset was already renamed; old/new info:' AS Comment,
                  _datasetNameOld AS Dataset_Name_Old,
                   DS.dataset     AS Dataset_Name_New,
                   DS.dataset_id,
                   DS.created     AS Dataset_Created,
                   DS.exp_id      AS Experiment_ID,
                   E.experiment   AS Experiment,
                   CASE WHEN _datasetAlreadyRenamed THEN 'Yes' ELSE 'No' END AS Dataset_Already_Renamed
            INTO _datasetInfo
            FROM t_dataset DS
                 INNER JOIN t_experiments AS E
                   ON DS.exp_id = E.exp_id
            WHERE DS.dataset = _datasetNameNew::citext;
        Else
            SELECT 'Dataset rename info:' AS Comment,
                   DS.Dataset      AS Dataset_Name_Old,
                   _datasetNameNew AS Dataset_Name_New,
                   DS.Dataset_ID,
                   DS.Created      AS Dataset_Created,
                   CASE WHEN DS.Exp_ID = _newExperimentID
                        THEN format('%s (Unchanged)', DS.Exp_ID)
                        ELSE format('%s -> %s', DS.Exp_ID, _newExperimentID)
                   END AS Experiment_ID,
                   CASE WHEN E.Experiment = _newExperiment
                        THEN format('%s (Unchanged)', E.Experiment)
                        ELSE format('%s -> %s', E.Experiment, _newExperiment)
                   END AS Experiment
            INTO _datasetInfo
            FROM t_dataset DS
                 INNER JOIN t_experiments AS E
                   ON DS.exp_id = E.exp_id
            WHERE dataset = _datasetNameOld::citext;
        End If;

        RAISE INFO '';
        RAISE INFO '%', _datasetInfo.Comment;
        RAISE INFO 'Dataset ID % (created %)', _datasetInfo.Dataset_ID, public.timestamp_text(_datasetInfo.Dataset_Created);
        RAISE INFO 'Old name: %', _datasetInfo.Dataset_Name_Old::text;
        RAISE INFO 'New name: %', _datasetInfo.Dataset_Name_New;
        RAISE INFO 'Experiment ID:   %', _datasetInfo.Experiment_ID;
        RAISE INFO 'Experiment Name: %', _datasetInfo.Experiment;

        If Exists (SELECT dataset_id FROM t_dataset_files WHERE dataset_id = _datasetID) Then
            RAISE INFO '';

            _formatSpecifier := '%-15s %-10s %-80s %-80s %-40s';

            _infoHead := format(_formatSpecifier,
                                'Dataset_File_ID',
                                'Dataset_ID',
                                'File_Path',
                                'File_Path_New',
                                'File_Hash'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---------------',
                                         '----------',
                                         '--------------------------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '----------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Dataset_File_ID,
                       Dataset_ID,
                       File_Path,
                       Replace(file_path, _datasetNameOld::citext, _datasetNameNew::citext) AS File_Path_New,
                       File_Hash
                FROM t_dataset_files
                WHERE dataset_id = _datasetID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset_File_ID,
                                    _previewData.Dataset_ID,
                                    _previewData.File_Path,
                                    _previewData.File_Path_New,
                                    _previewData.File_Hash
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

    End If;

    _formatSpecifier := '%-9s %-80s %-10s %-11s %-10s %-50s %-60s %-80s %-25s %-20s %-20s';

    _infoHead := format(_formatSpecifier,
                        'Request',
                        'Name',
                        'Status',
                        'Queue_State',
                        'Origin',
                        'Campaign',
                        'Experiment',
                        'Dataset',
                        'Instrument',
                        'Request_Run_Start',
                        'Request_Run_Finish'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '---------',
                                 '--------------------------------------------------------------------------------',
                                 '----------',
                                 '-----------',
                                 '----------',
                                 '--------------------------------------------------',
                                 '------------------------------------------------------------',
                                 '--------------------------------------------------------------------------------',
                                 '-------------------------',
                                 '--------------------',
                                 '--------------------'
                                );

    If _newRequestedRunID <= 0 Then
        --------------------------------------------
        -- Show Requested Runs that may need to be updated, filtering on dataset name matching _datasetNameOld or _datasetNameNew
        -- Also show requested runs with the same experiment name or with an experiment name that starts with _experiment
        --------------------------------------------

        RAISE INFO '';
        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT RL.Request,
                   RL.Name,
                   RL.Status,
                   RL.Queue_State,
                   RL.Origin,
                   RL.Campaign,
                   RL.Experiment,
                   RL.Dataset,
                   RL.Instrument,
                   public.timestamp_text(RR.request_run_start)  AS Request_Run_Start,
                   public.timestamp_text(RR.request_run_finish) AS Request_Run_Finish
            FROM V_Requested_Run_List_Report_2 RL
                 INNER JOIN t_requested_run RR
                   ON RL.Request = RR.request_id
            WHERE RL.Dataset IN (_datasetNameOld::citext, _datasetNameNew::citext) OR
                  _showRequestedRunsByExperiment And Coalesce(_experiment, '') <> '' AND RL.Name ILIKE _experiment || '%'
            ORDER BY CASE WHEN RL.Dataset = _datasetNameOld::citext THEN '0'
                          WHEN RL.Dataset = _datasetNameNew::citext THEN '1'
                          ELSE '2_' || RL.Name
                     END
            LIMIT 100
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Request,
                                _previewData.Name,
                                _previewData.Status,
                                _previewData.Queue_State,
                                _previewData.Origin,
                                _previewData.Campaign,
                                _previewData.Experiment,
                                _previewData.Dataset,
                                _previewData.Instrument,
                                _previewData.Request_Run_Start,
                                _previewData.Request_Run_Finish
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else

        If Not _infoOnly And Not _datasetAlreadyRenamed Then
            UPDATE t_requested_run
            SET dataset_id         = Null,
                request_run_start  = Null,
                request_run_finish = Null,
                state_name         = 'Active',
                queue_state        = 2          -- Assigned
            WHERE request_id = _requestedRunInfo.OldRequestedRunID;

            UPDATE t_requested_run
            SET dataset_id         = _datasetID,
                request_run_start  = _requestedRunInfo.RunStart,
                request_run_finish = _requestedRunInfo.RunFinish,
                cart_id            = _requestedRunInfo.CartId,
                cart_config_id     = _requestedRunInfo.CartConfigID,
                cart_column        = _requestedRunInfo.CartColumn,
                state_name         = 'Completed',
                queue_state        = 3          -- Analyzed
            WHERE request_id = _newRequestedRunID;
        End If;

        --------------------------------------------
        -- Show Requested Runs that may need to be updated,
        -- filtering on request_id matching _requestedRunInfo.OldRequestedRunID or _newRequestedRunID
        --------------------------------------------

        RAISE INFO '';
        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT RL.Request,
                   RL.Name,
                   RL.Status,
                   RL.Queue_State,
                   RL.Origin,
                   RL.Campaign,
                   RL.Experiment,
                   RL.Dataset,
                   RL.Instrument,
                   public.timestamp_text(RR.request_run_start)  AS Request_Run_Start,
                   public.timestamp_text(RR.request_run_finish) AS Request_Run_Finish
            FROM V_Requested_Run_List_Report_2 RL
                 INNER JOIN t_requested_run RR
                   ON RL.Request = RR.request_id
            WHERE RL.Request IN (_requestedRunInfo.OldRequestedRunID, _newRequestedRunID)
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Request,
                                _previewData.Name,
                                _previewData.Status,
                                _previewData.Queue_State,
                                _previewData.Origin,
                                _previewData.Campaign,
                                _previewData.Experiment,
                                _previewData.Dataset,
                                _previewData.Instrument,
                                _previewData.request_run_start,
                                _previewData.request_run_finish
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    --------------------------------------------
    -- Create a temporary table to first track
    -- capture task jobs in cap.t_tasks, then later track
    -- analysis jobs in sw.t_jobs
    --------------------------------------------

    CREATE TEMP TABLE Tmp_JobsToUpdate (
         Job int NOT NULL
    );

    --------------------------------------------
    -- Update capture task jobs in cap.t_tasks
    --------------------------------------------

    INSERT INTO Tmp_JobsToUpdate (Job)
    SELECT Job
    FROM cap.t_tasks
    WHERE dataset = _datasetNameOld::citext
    ORDER BY Job;

    RAISE INFO '';

    If Not Exists (SELECT T.Job
                   FROM cap.t_tasks T
                        INNER JOIN Tmp_JobsToUpdate JU
                          ON T.job = JU.job)
    Then
        RAISE INFO 'No capture task jobs exist in cap.t_tasks for dataset %', _datasetNameOld;
    Else
        _formatSpecifier := '%-12s %-25s %-5s %-80s %-80s %-10s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Capture_Task',
                            'Script',
                            'State',
                            'Dataset',
                            'Dataset_Name_New',
                            'Dataset_ID',
                            'Imported'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------',
                                     '-------------------------',
                                     '-----',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------------------------------------------------------------------',
                                     '----------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT T.Job AS Capture_Task,
                   T.Script,
                   T.State,
                   T.Dataset,
                   _datasetNameNew AS Dataset_Name_New,
                   T.Dataset_ID,
                   public.timestamp_text(T.Imported) AS Imported
            FROM cap.t_tasks T
                 INNER JOIN Tmp_JobsToUpdate JU
                   ON T.job = JU.job
            ORDER BY T.Job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Capture_Task,
                                _previewData.Script,
                                _previewData.State,
                                _previewData.Dataset,
                                _previewData.Dataset_Name_New,
                                _previewData.Dataset_ID,
                                _previewData.Imported
                               );

            RAISE INFO '%', _infoData;
        END LOOP;
    End If;

    If Not _infoOnly Then
        --------------------------------------------
        -- Update capture task jobs in cap.t_tasks
        --------------------------------------------

        FOR _job IN
            SELECT Job
            FROM Tmp_JobsToUpdate
            ORDER BY Job
        LOOP
            CALL cap.add_update_task_parameter (_job, 'JobParameters', 'Dataset',   _datasetNameNew, _message => _msg, _returnCode => _returnCode, _infoOnly => false);
            CALL cap.add_update_task_parameter (_job, 'JobParameters', 'Directory', _datasetNameNew, _message => _msg, _returnCode => _returnCode, _infoOnly => false);

            UPDATE cap.t_tasks
            SET Dataset = _datasetNameNew
            WHERE Job = _job;
        END LOOP;

    End If;

    --------------------------------------------
    -- Update jobs in sw.t_jobs
    --------------------------------------------

    TRUNCATE Tmp_JobsToUpdate;

    INSERT INTO Tmp_JobsToUpdate (Job)
    SELECT Job
    FROM sw.t_jobs
    WHERE Dataset = _datasetNameOld::citext
    ORDER BY Job;

    RAISE INFO '';

    If Not Exists (SELECT J.Job
                   FROM sw.t_jobs J
                        INNER JOIN Tmp_JobsToUpdate JU
                          ON J.job = JU.job)
    Then
        RAISE INFO 'No analysis jobs exist in sw.t_jobs for dataset %', _datasetNameOld;
    Else
        _formatSpecifier := '%-12s %-25s %-5s %-80s %-80s %-10s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Pipeline_Job',
                            'Script',
                            'State',
                            'Dataset',
                            'Dataset_Name_New',
                            'Dataset_ID',
                            'Imported'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------',
                                     '-------------------------',
                                     '-----',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------------------------------------------------------------------',
                                     '----------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT J.Job AS Pipeline_Job,
                   J.Script,
                   J.State,
                   J.Dataset,
                   _datasetNameNew AS Dataset_Name_New,
                   J.Dataset_ID,
                   public.timestamp_text(J.Imported) AS Imported
            FROM sw.t_jobs J
                 INNER JOIN Tmp_JobsToUpdate JU
                   ON J.job = JU.job
            ORDER BY J.Job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Pipeline_Job,
                                _previewData.Script,
                                _previewData.State,
                                _previewData.Dataset,
                                _previewData.Dataset_Name_New,
                                _previewData.Dataset_ID,
                                _previewData.Imported
                               );

            RAISE INFO '%', _infoData;
        END LOOP;
    End If;

    If Not _infoOnly Then
        --------------------------------------------
        -- Update analysis jobs in sw.t_jobs
        --------------------------------------------

        FOR _job IN
            SELECT Job
            FROM Tmp_JobsToUpdate
            ORDER BY Job
        LOOP
            CALL sw.add_update_job_parameter (_job, 'JobParameters', 'DatasetName',       _datasetNameNew, _message => _msg, _returnCode => _returnCode, _infoOnly => false);
            CALL sw.add_update_job_parameter (_job, 'JobParameters', 'DatasetFolderName', _datasetNameNew, _message => _msg, _returnCode => _returnCode, _infoOnly => false);

            UPDATE sw.t_jobs
            SET Dataset = _datasetNameNew
            WHERE Job = _job;
        END LOOP;

    End If;

    If _infoOnly Then
        --------------------------------------------
        -- Update cached dataset names in t_data_package_datasets
        --------------------------------------------

        UPDATE dpkg.t_data_package_datasets
        SET dataset = _datasetNameNew
        WHERE dataset_id = _datasetID AND
              dataset IS DISTINCT FROM _datasetNameNew;
    End If;

    --------------------------------------------
    -- Show commands for renaming the dataset directory and .raw file
    --------------------------------------------

    RAISE INFO '';
    RAISE INFO 'pushd %',          _storageServerSharePath;
    RAISE INFO 'move % %',         _datasetNameOld, _datasetNameNew;
    RAISE INFO 'cd %',             _datasetNameNew;
    RAISE INFO 'move %.raw %.raw', _datasetNameOld, _datasetNameNew;

    --------------------------------------------
    -- Show example commands for renaming the job files
    --------------------------------------------

    CREATE TEMP TABLE Tmp_Extensions (
        SuffixID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        FileSuffix text NOT null
    );

    CREATE UNIQUE INDEX IX_Tmp_Extensions_ID on Tmp_Extensions(SuffixID);
    CREATE UNIQUE INDEX IX_Tmp_Extensions_Suffix on Tmp_Extensions(FileSuffix);

    TRUNCATE Tmp_JobsToUpdate;

    -- Find jobs associated with this dataset

    -- Use view V_Analysis_Job_Export to find completed jobs (State = 4)
    -- associated with datasets with the following dataset ratings
    --  -6: Rerun (Good Data)
    --   1: No Interest
    --   2: Unknown
    --   3: Interest
    --   5: Released

    INSERT INTO Tmp_JobsToUpdate (Job)
    SELECT Job
    FROM V_Analysis_Job_Export
    WHERE NOT _infoOnly AND Dataset = _datasetNameNew::citext
          OR  _infoOnly AND Dataset = _datasetNameOld::citext
    ORDER BY Job;

    _continue           := true;
    _job                := 0;
    _jobFileUpdateCount := 0;

    --------------------------------------------
    -- Use a while loop to process each job, not a for loop,
    -- since, after the file renames for the jobs are shown,
    -- the file renames for the QC subdirectory will be shown
    --------------------------------------------

    WHILE _continue
    LOOP
        DELETE FROM Tmp_Extensions;

        SELECT Job
        INTO _job
        FROM Tmp_JobsToUpdate
        WHERE Job > _job
        ORDER BY Job
        LIMIT 1;

        If Not FOUND Then
            --------------------------------------------
            -- No more jobs; show example commands for renaming QC files
            --------------------------------------------

            _continue := false;
            _resultsFolder := 'QC';

            INSERT INTO Tmp_Extensions (FileSuffix)
            VALUES ('_BPI_MS.png'),       ('_BPI_MSn.png'),
                   ('_HighAbu_LCMS.png'), ('_HighAbu_LCMS_MSn.png'),
                   ('_LCMS.png'),         ('_LCMS_MSn.png'),
                   ('_TIC.png'),          ('_DatasetInfo.xml');

        Else
            SELECT Tool.tool_base_name,
                   J.results_folder_name
            INTO _toolBaseName, _resultsFolder
            FROM t_analysis_job J
                 INNER JOIN t_analysis_tool Tool
                   ON J.analysis_tool_id = Tool.analysis_tool_id
            WHERE Job = _job;

            If FOUND Then
                If _toolBaseName = 'Decon2LS' Then
                    INSERT INTO Tmp_Extensions (FileSuffix)
                    VALUES ('_isos.csv'),   ('_scans.csv'),
                           ('_BPI_MS.png'), ('_HighAbu_LCMS.png'), ('_HighAbu_LCMS_zoom.png'),
                           ('_LCMS.png'),   ('_LCMS_zoom.png'),
                           ('_TIC.png'),    ('_log.txt');
                End If;

                If _toolBaseName = 'MASIC' Then
                    INSERT INTO Tmp_Extensions (FileSuffix)
                    VALUES ('_MS_scans.csv'),  ('_MSMS_scans.csv'), ('_MSMethod.txt'),
                           ('_ScanStats.txt'), ('_ScanStatsConstant.txt'), ('_ScanStatsEx.txt'),
                           ('_SICstats.txt'),  ('_DatasetInfo.xml'), ('_SICs.zip'),
                           ('_PeakAreaHistogram.png'), ('_PeakWidthHistogram.png'),
                           ('_RepIonObsRate.png'),
                           ('_RepIonObsRateHighAbundance.png'),
                           ('_RepIonStatsHighAbundance.png'),
                           ('_RepIonObsRate.txt'), ('_RepIonStats.txt'), ('_ReporterIons.txt');
                End If;

                If _toolBaseName Like 'MSGFPlus%' Then
                    INSERT INTO Tmp_Extensions (FileSuffix)
                    VALUES ('_msgfplus.mzid.gz'),             ('_msgfplus_fht.txt'), ('_msgfplus_fht_MSGF.txt'),
                           ('_msgfplus_PepToProtMap.txt'),    ('_msgfplus_PepToProtMapMTS.txt'),
                           ('_msgfplus_syn.txt'),             ('_msgfplus_syn_ModDetails.txt'),
                           ('_msgfplus_syn_ModSummary.txt'),  ('_msgfplus_syn_MSGF.txt'),
                           ('_msgfplus_syn_ProteinMods.txt'), ('_msgfplus_syn_ResultToSeqMap.txt'),
                           ('_msgfplus_syn_SeqInfo.txt'),     ('_msgfplus_syn_SeqToProteinMap.txt'),
                           ('_ScanType.txt'),                 ('_pepXML.zip');

                End If;
            End If;
        End If;

        If _jobFileUpdateCount = 0 And Exists (SELECT Job FROM Tmp_JobsToUpdate) Then
            RAISE INFO '%', 'rem Example commands for renaming job files';
        End If;

        RAISE INFO '';
        RAISE INFO 'cd %', _resultsFolder;

        FOR _suffixID, _fileSuffix IN
            SELECT SuffixID, FileSuffix
            FROM Tmp_Extensions
            ORDER BY SuffixID
        LOOP
            RAISE INFO 'Move % %',
                        format('%s%s', _datasetNameOld, _fileSuffix),
                        format('%s%s', _datasetNameNew, _fileSuffix);

            _jobFileUpdateCount := _jobFileUpdateCount + 1;
        END LOOP;

        If _resultsFolder = 'QC' Then
            _datasetInfoFile := format('%s_DatasetInfo.xml', _datasetNameNew);

            RAISE INFO '';
            RAISE INFO 'rem Use sed to change the dataset names in index.html';
            RAISE INFO 'cat index.html | sed -r "s/%/%/g" > index_new.html', _datasetNameOld, _datasetNameNew;
            RAISE INFO 'move index.html index_old.html';
            RAISE INFO 'move index_new.html index.html';

            RAISE INFO '';
            RAISE INFO 'rem Use sed to change the dataset names in DatasetName_DatasetInfo.xml';
            RAISE INFO 'cat % | sed -r "s/%/%/g" > DatasetInfo_new.xml', _datasetInfoFile, _datasetNameOld, _datasetNameNew;
            RAISE INFO 'move % DatasetInfo_old.xml', _datasetInfoFile;
            RAISE INFO 'move DatasetInfo_new.xml %', _datasetInfoFile;
        End If;

        If _resultsFolder Like 'SIC%' Then
            RAISE INFO '';
            RAISE INFO 'rem Use sed to change the dataset names in index.html';
            RAISE INFO 'cat index.html | sed -r "s/%/%/g" > index_new.html', _datasetNameOld, _datasetNameNew;
            RAISE INFO 'move index.html index_old.html';
            RAISE INFO 'move index_new.html index.html';
        End If;

        RAISE INFO '%', 'cd ..';

        If _resultsFolder = 'QC' Then
            -- Break out of the while loop
            EXIT;
        End If;

        -- Look for a MzRefinery directory for this job

        SELECT Output_Folder_Name
        INTO _mzRefineryOutputFolder
        FROM sw.t_job_steps
        WHERE Job = _job AND
              State <> 3 AND
              Tool = 'Mz_Refinery';

        If Not FOUND Then
            CONTINUE;
        End If;

        RAISE INFO '';
        RAISE INFO 'cd %', _mzRefineryOutputFolder;
        RAISE INFO 'move %_msgfplus.mzid.gz             %_msgfplus.mzid.gz', _datasetNameOld, _datasetNameNew;
        RAISE INFO 'move %_MZRefinery_Histograms.png    %_MZRefinery_Histograms.png', _datasetNameOld, _datasetNameNew;
        RAISE INFO 'move %_MZRefinery_MassErrors.png    %_MZRefinery_MassErrors.png', _datasetNameOld, _datasetNameNew;
        RAISE INFO 'move %_msgfplus.mzRefinement.tsv    %_msgfplus.mzRefinement.tsv', _datasetNameOld, _datasetNameNew;
        RAISE INFO 'move %.mzML.gz_CacheInfo.txt        %.mzML.gz_CacheInfo.txt', _datasetNameOld, _datasetNameNew;
        RAISE INFO '';
        RAISE INFO 'rem Use sed to change the dataset name in the _CacheInfo.txt file';
        RAISE INFO 'cat %.mzML.gz_CacheInfo.txt | sed -r "s/%/%/g" > _CacheInfo.txt.new', _datasetNameNew, _datasetNameOld, _datasetNameNew;
        RAISE INFO 'move %.mzML.gz_CacheInfo.txt %.mzML.gz_OldCacheInfo.txt', _datasetNameNew, _datasetNameNew;
        RAISE INFO 'move _CacheInfo.txt.new %.mzML.gz_CacheInfo.txt', _datasetNameNew;

        RAISE INFO 'rem ToDo: rename or delete the .mzML.gz file at:';
        RAISE INFO 'cat %.mzML.gz_CacheInfo.txt', _datasetNameNew;
        RAISE INFO 'cd ..';

    END LOOP;

    RAISE INFO '';
    RAISE INFO '%', 'popd';
    RAISE INFO '';

    If _jobFileUpdateCount > 0 Then
        _msg := format('See the console output for %s dataset/job file update %s',
                       _jobFileUpdateCount,
                       public.check_plural(_jobFileUpdateCount, 'command', 'commands'));

        RAISE INFO '%', _msg;

        If _message = '' Then
            _message := _msg;
        Else
            _message := public.append_to_text(_message, Lower(_msg));
        End If;
    End If;

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

    DROP TABLE Tmp_Extensions;
    DROP TABLE Tmp_JobsToUpdate;
END
$$;


ALTER PROCEDURE public.rename_dataset(IN _datasetnameold text, IN _datasetnamenew text, IN _newrequestedrunid integer, IN _infoonly boolean, IN _showrequestedrunsbyexperiment boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

