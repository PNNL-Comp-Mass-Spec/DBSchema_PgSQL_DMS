--
CREATE OR REPLACE PROCEDURE public.rename_dataset
(
    _datasetNameOld text = '',
    _datasetNameNew text = '',
    _newRequestedRunID int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = true
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Renames a dataset in T_Dataset
**      Renames associated jobs in the DMS_Capture and DMS_Pipeline databases
**
**  Auth:   mem
**  Date:   01/25/2013 mem - Initial version
**          07/08/2016 mem - Now show old/new names and jobs even when _infoOnly is false
**          12/06/2016 mem - Include file rename statements
**          03/06/2017 mem - Validate that _datasetNameNew is no more than 80 characters long
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/03/2018 mem - Rename files in T_Dataset_Files
**                         - Update commands for renaming the dataset directory and dataset file
**          08/06/2018 mem - Fix where clause when querying V_Analysis_Job_Export
**                         - Look for requested runs that may need to be updated
**          01/04/2019 mem - Add sed command for updating the index.html file in the QC directory
**          01/20/2020 mem - Show the File_Hash in T_Dataset_Files when previewing updates
**                         - Add commands for updating the DatasetInfo.xml file with sed
**                         - Switch from Folder to Directory when calling AddUpdateJobParameter
**          02/19/2021 mem - Validate the characters in the new dataset name
**          11/04/2021 mem - Add more MASIC file names and use sed to edit MASIC's index.html file
**          11/05/2021 mem - Add more MASIC file names and rename files in any MzRefinery directories
**          07/21/2022 mem - Move misplaced 'cd ..' and add missing 'rem'
**          10/10/2022 mem - Add _newRequestedRunID; if defined (and active), associate the dataset with this Request ID and use it to update the dataset's experiment
**          04/25/2023 mem - Update Queue_State for the old and new requested runs
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetID int := 0;
    _experiment text;
    _datasetAlreadyRenamed boolean := false;
    _datasetFolderPath text := '';
    _storageServerSharePath text;
    _lastSlashReverseText int;
    _newExperimentID Int;
    _newExperiment text;
    _requestedRunState text;
    _oldRequestedRunID int;
    _runStart timestamp;
    _runFinish timestamp;
    _cartId int;
    _cartConfigID int;
    _cartColumn int;
    _job int := 0;
    _suffixID int;
    _fileSuffix text;
    _continue boolean;
    _job int;
    _toolBaseName citext;
    _resultsFolder text;
    _mzRefineryOutputFolder text;
    _badCh text;
    _jobFileUpdateCount int := 0;
    _datasetInfoFile text;
BEGIN
    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------
    --
    _datasetNameOld := Coalesce(_datasetNameOld, '');
    _datasetNameNew := Coalesce(_datasetNameNew, '');
    _newRequestedRunID := Coalesce(_newRequestedRunID, 0);

    If _datasetNameOld = '' Then
        _message := '_datasetNameOld is empty; unable to continue';
        RETURN;
    End If;

    If _datasetNameNew = '' Then
        _message := '_datasetNameNew is empty; unable to continue';
        RETURN;
    End If;

    If char_length(_datasetNameNew) > 80 Then
        _message := 'New dataset name cannot be more than 80 characters in length';
        RETURN;
    End If;

    _badCh := public.validate_chars(_datasetNameNew, '');

    If _badCh <> '' Then
        If _badCh = 'space' Then
            _message := 'New dataset name may not contain spaces';
        ElsIf char_length(_badCh) = 1 Then
            _message := 'New dataset name may not contain the character ' || _badCh;
        Else
            _message := 'New dataset name may not contain the characters ' || _badCh;
        End If;

        RETURN;
    End If;

    --------------------------------------------
    -- Lookup the dataset ID
    --------------------------------------------
    --
    SELECT dataset_id,
           exp_id
    INTO _datasetID, _newExperimentID
    FROM t_dataset
    WHERE dataset = _datasetNameOld;

    If Not FOUND Then
        -- Old dataset name not found; perhaps it was already renamed in t_dataset
        SELECT dataset_id,
               exp_id
        INTO _datasetID, _newExperimentID
        FROM t_dataset
        WHERE dataset = _datasetNameNew;

        If FOUND Then
            -- Lookup the experiment for this dataset (using the new name)
            SELECT Experiment
            INTO _experiment
            FROM V_Dataset_Export
            WHERE Dataset = _datasetNameNew;

            _datasetAlreadyRenamed := true;
        End If;
    Else

        -- Old dataset name found; make sure the new name is not already in use
        If Exists (SELECT * FROM t_dataset WHERE dataset = _datasetNameNew) Then
            _message := 'New dataset name already exists; unable to rename ' || _datasetNameOld || ' to ' || _datasetNameNew;
            RETURN;
        End If;

        -- Lookup the experiment for this dataset (using the old name)
        SELECT Experiment
        INTO _experiment
        FROM V_Dataset_Export
        WHERE Dataset = _datasetNameOld;
    End If;

    If _datasetID = 0 Then
        _message := 'Dataset not found using either the old name or the new name (' ||  _datasetNameOld || ' or ' || _datasetNameNew || ')';
        RETURN;
    End If;

    If _newRequestedRunID = 0 Then
        _message := 'Specify the new requested run ID using _newRequestedRunID (must be active); use -1 to leave the requested run ID unchanged';
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
            RETURN;
        End If;

        If Not _datasetAlreadyRenamed And _requestedRunState <> 'Active' Then
            _message := format('New requested run is not active: %s', _newRequestedRunID);
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
    SELECT request_id As OldRequestedRunID
           request_run_start As RunStart,
           request_run_finish As RunFinish,
           cart_id As CartId,
           cart_config_id As CartConfigID,
           cart_column As CartColumn
    INTO _requestedRunInfo
    FROM t_requested_run
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        _message := format('Dataset ID not found in t_requested_run: %s', _datasetID);
        RETURN;
    End If;

    -- Lookup the experiment name for _newExperimentID
    SELECT experiment INTO _newExperiment
    FROM t_experiments
    WHERE exp_id = _newExperimentID

    If Not _infoOnly Then
        --------------------------------------------
        -- Rename the dataset in t_dataset
        --------------------------------------------
        --
        If Not _datasetAlreadyRenamed And Not Exists (Select * from t_dataset WHERE dataset = _datasetNameNew) Then
            -- Show the old and new values

            RETURN QUERY
            SELECT DS.Dataset_Name  AS Dataset_Name_Old,
                   _datasetNameNew AS Dataset_Name_New,
                   DS.Dataset_ID,
                   DS.Created   AS Dataset_Created,
                   CASE WHEN DS.Exp_ID = _newExperimentID
                        THEN DS.Exp_ID::text || ' (Unchanged)'
                        ELSE DS.Exp_ID::text || ' -> ' || _newExperimentID::text
                   END AS Experiment_ID,
                   CASE WHEN E.Experiment = _newExperiment
                        THEN E.Experiment || ' (Unchanged)'
                        ELSE E.Experiment || ' -> ' || _newExperiment
                   END AS Experiment
            FROM t_dataset DS
                 INNER JOIN t_experiments AS E
                   ON DS.exp_id = E.exp_id
            WHERE DS.dataset IN (_datasetNameOld, _datasetNameNew)

            -- Rename the dataset and update the experiment ID (if changed)
            UPDATE t_dataset
            SET dataset = _datasetNameNew,
                folder_name = _datasetNameNew,
                exp_id = _newExperimentID
            WHERE dataset_id = _datasetID AND dataset = _datasetNameOld;

            _message := format('rem Renamed dataset "%s" to "%s"', _datasetNameOld, _datasetNameNew);
            RAISE INFO '%', _message;

            Call post_log_entry ('Normal', _message, 'RenameDataset');
        End If;

        -- Rename any files in t_dataset_files
        If Exists (Select * from t_dataset_files WHERE dataset_id = _datasetID) Then
            UPDATE t_dataset_files
            SET file_path = REPLACE(file_path, _datasetNameOld, _datasetNameNew)
            WHERE Dataset_ID = _datasetID;
        End If;

    Else

        -- Preview the changes
        If Exists (Select * from t_dataset WHERE dataset = _datasetNameNew) Then
            -- The dataset was already renamed
            RETURN QUERY
            SELECT _datasetNameOld  AS Dataset_Name_Old,
                   DS.dataset   AS Dataset_Name_New,
                   DS.dataset_id,
                   DS.created    AS Dataset_Created,
                   DS.exp_id        AS Experiment_ID,
                   E.experiment AS Experiment,
                   Case When _datasetAlreadyRenamed Then 'Yes' Else 'No' End As Dataset_Already_Renamed
            FROM t_dataset DS
                 INNER JOIN t_experiments AS E
                   ON DS.exp_id = E.exp_id
            WHERE DS.dataset = _datasetNameNew
        Else

            RETURN QUERY
            SELECT Dataset_Name     AS Dataset_Name_Old,
                   _datasetNameNew AS Dataset_Name_New,
                   Dataset_ID,
                   Created      AS Dataset_Created,
                   CASE WHEN DS.Exp_ID = _newExperimentID
                        THEN DS.Exp_ID::text || ' (Unchanged)'
                        ELSE DS.Exp_ID::text || ' -> ' || _newExperimentID::text
                   END AS Experiment_ID,
                   CASE WHEN E.Experiment = _newExperiment
                        THEN E.Experiment || ' (Unchanged)'
                        ELSE E.Experiment || ' -> ' || _newExperiment
                   END AS Experiment
            FROM t_dataset DS
                 INNER JOIN t_experiments AS E
                   ON DS.exp_id = E.exp_id
            WHERE dataset = _datasetNameOld
        End If;

        If Exists (Select * from t_dataset_files WHERE dataset_id = _datasetID) Then

            -- ToDo: Update this to use RAISE INFO

            SELECT dataset_file_id,
                   dataset_id,
                   file_path,
                   REPLACE(file_path, _datasetNameOld, _datasetNameNew) AS File_Path_New,
                   file_hash
            FROM t_dataset_files
            WHERE dataset_id = _datasetID
        End If;

    End If;

    If _newRequestedRunID <= 0 Then
        --------------------------------------------
        -- Show Requested Runs that may need to be updated
        --------------------------------------------

        -- ToDo: Update this to use RAISE INFO

        SELECT RL.Request,
               RL.Name,
               RL.Status,
               RL.Queue_State
               RL.origin,
               RL.Campaign,
               RL.Experiment,
               RL.Dataset,
               RL.Instrument,
               RR.request_run_start,
               RR.request_run_finish
        FROM V_Requested_Run_List_Report_2 RL
             INNER JOIN t_requested_run RR
               ON RL.Request = RR.request_id
        WHERE RL.Dataset IN (_datasetNameOld, _datasetNameNew) OR
              RL.Name LIKE _experiment || '%'
    Else

        If Not _infoOnly And Not _datasetAlreadyRenamed Then
            UPDATE t_requested_run
            SET dataset_id         = Null,
                request_run_start  = Null,
                request_run_finish = Null,
                state_name         = 'Active',
                queue_state        = 2          -- Assigned
            WHERE request_id = _oldRequestedRunID

            UPDATE t_requested_run
            SET dataset_id         = _datasetID,
                request_run_start  = _runStart,
                request_run_finish = _runFinish,
                cart_id            = _cartId,
                cart_config_id     = _cartConfigID,
                cart_column        = _cartColumn,
                state_name         = 'Completed',
                queue_state        = 3          -- Analyzed
            WHERE request_id = _newRequestedRunID
        End If;

        -- ToDo: Update this to use RAISE INFO

        SELECT RL.Request,
               RL.Name,
               RL.Status,
               RL.origin,
               RL.Campaign,
               RL.Experiment,
               RL.Dataset,
               RL.Instrument,
               RR.request_run_start,
               RR.request_run_finish
        FROM V_Requested_Run_List_Report_2 RL
             INNER JOIN t_requested_run RR
               ON RL.Request = RR.request_id
        WHERE RL.Request IN (_oldRequestedRunID, _newRequestedRunID)
    End If;

    --------------------------------------------
    -- Update jobs in the DMS_Capture database
    --------------------------------------------
    --
    CREATE TEMP TABLE Tmp_JobsToUpdate (
         Job int not null
    );

    INSERT INTO Tmp_JobsToUpdate (Job)
    SELECT Job
    FROM cap.t_tasks
    WHERE dataset = _datasetNameOld
    ORDER BY Job;

    -- ToDo: Update this to use RAISE INFO

    SELECT Job AS Capture_Task,
           Script,
           State,
           Dataset,
           _datasetNameNew As Dataset_Name_New,
           Dataset_ID,
           Imported
    FROM cap.t_tasks
    WHERE Job In (Select Job from Tmp_JobsToUpdate)

    If Not _infoOnly Then
        --------------------------------------------
        -- Update capture task jobs in DMS_Capture
        --------------------------------------------
        --
        FOR _job IN
            SELECT Job
            FROM Tmp_JobsToUpdate
            ORDER BY Job
        LOOP
            Call cap.add_update_job_parameter (_job, 'JobParameters', 'Dataset',   _datasetNameNew, _infoOnly => false);
            Call cap.add_update_job_parameter (_job, 'JobParameters', 'Directory', _datasetNameNew, _infoOnly => false);

            UPDATE cap.t_tasks
            Set Dataset = _datasetNameNew
            WHERE Job = _job;
        END LOOP;

    End If;

    --------------------------------------------
    -- Update jobs in the DMS_Pipeline database
    --------------------------------------------
    --
    DELETE FROM Tmp_JobsToUpdate;

    INSERT INTO Tmp_JobsToUpdate (Job)
    SELECT Job
    FROM sw.T_Jobs
    WHERE Dataset = _datasetNameOld
    ORDER BY Job

    -- ToDo: Update this to use RAISE INFO

    SELECT Job AS Pipeline_Job,
           Script,
           State,
           Dataset,
           _datasetNameNew as Dataset_Name_New,
           Dataset_ID,
           Imported
    FROM sw.T_Jobs
    WHERE Job In (Select Job from Tmp_JobsToUpdate)

    If Not _infoOnly Then
        FOR _job IN
            SELECT Job
            FROM Tmp_JobsToUpdate
            ORDER BY Job
        LOOP
            Call sw.add_update_job_parameter (_job, 'JobParameters', 'DatasetName',       _datasetNameNew, _infoOnly => false);
            Call sw.add_update_job_parameter (_job, 'JobParameters', 'DatasetFolderName', _datasetNameNew, _infoOnly => false);

            UPDATE sw.T_Jobs
            Set Dataset = _datasetNameNew
            WHERE Job = _job;

        END LOOP;

    End If;

    --------------------------------------------
    -- Show commands for renaming the dataset directory and .raw file
    --------------------------------------------
    --
    RAISE INFO '%', 'pushd ' || _storageServerSharePath;
    RAISE INFO '%', 'move '  || _datasetNameOld || ' ' || _datasetNameNew;
    RAISE INFO '%', 'cd '    || _datasetNameNew;
    RAISE INFO '%', 'move '  || _datasetNameOld || '.raw ' || _datasetNameNew || '.raw';

    --------------------------------------------
    -- Show example commands for renaming the job files
    --------------------------------------------
    --
    CREATE TEMP TABLE Tmp_Extensions (
        SuffixID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        FileSuffix text NOT null
    )

    CREATE UNIQUE INDEX IX_Tmp_Extensions_ID on Tmp_Extensions(SuffixID);
    CREATE UNIQUE INDEX IX_Tmp_Extensions_Suffix on Tmp_Extensions(FileSuffix);

    DELETE FROM Tmp_JobsToUpdate;

    -- Find jobs associated with this dataset
    -- Only shows jobs that would be exported to MTS
    -- If the dataset has rating Not Released, no jobs will appear in V_Analysis_Job_Export
    INSERT INTO Tmp_JobsToUpdate (Job)
    SELECT Job
    FROM V_Analysis_Job_Export
    WHERE Not _infoOnly And Dataset = _datasetNameNew
          Or  _infoOnly And Dataset = _datasetNameOld
    ORDER BY Job

    _continue := true;
    _job := 0;

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
            --
            _continue := false;
            _resultsFolder := 'QC';

            INSERT INTO Tmp_Extensions (FileSuffix) VALUES
                ('_BPI_MS.png'),('_BPI_MSn.png'),
                ('_HighAbu_LCMS.png'),('_HighAbu_LCMS_MSn.png'),
                ('_LCMS.png'),('_LCMS_MSn.png'),
                ('_TIC.png'),('_DatasetInfo.xml');
        Else
            SELECT Tool.tool_base_name,
                   AJE.ResultsFolder
            INTO _toolBaseName, _resultsFolder
            FROM V_Analysis_Job_Export AJE
                 INNER JOIN t_analysis_tool Tool
                   ON AJE.AnalysisTool = Tool.analysis_tool
            WHERE Job = _job;

            If FOUND Then
                If _toolBaseName = 'Decon2LS' Then
                    INSERT INTO Tmp_Extensions (FileSuffix) VALUES
                        ('_isos.csv'), ('_scans.csv'),
                        ('_BPI_MS.png'), ('_HighAbu_LCMS.png'), ('_HighAbu_LCMS_zoom.png'),
                        ('_LCMS.png'), ('_LCMS_zoom.png'),
                        ('_TIC.png'), ('_log.txt')
                End If;

                If _toolBaseName = 'MASIC' Then
                    INSERT INTO Tmp_Extensions (FileSuffix) VALUES
                        ('_MS_scans.csv'), ('_MSMS_scans.csv'),('_MSMethod.txt'),
                        ('_ScanStats.txt'), ('_ScanStatsConstant.txt'), ('_ScanStatsEx.txt'),
                        ('_SICstats.txt'),('_DatasetInfo.xml'),('_SICs.zip'),
                        ('_PeakAreaHistogram.png'),('_PeakWidthHistogram.png'),
                        ('_RepIonObsRate.png'),
                        ('_RepIonObsRateHighAbundance.png'),
                        ('_RepIonStatsHighAbundance.png'),
                        ('_RepIonObsRate.txt'),('_RepIonStats.txt'),('_ReporterIons.txt')
                End If;

                If _toolBaseName Like 'MSGFPlus%' Then
                    INSERT INTO Tmp_Extensions (FileSuffix) VALUES
                        ('_msgfplus.mzid.gz'),('_msgfplus_fht.txt'), ('_msgfplus_fht_MSGF.txt'),
                        ('_msgfplus_PepToProtMap.txt'), ('_msgfplus_PepToProtMapMTS.txt'),
                        ('_msgfplus_syn.txt'), ('_msgfplus_syn_ModDetails.txt'),
                        ('_msgfplus_syn_ModSummary.txt'),('_msgfplus_syn_MSGF.txt'),
                        ('_msgfplus_syn_ProteinMods.txt'),('_msgfplus_syn_ResultToSeqMap.txt'),
                        ('_msgfplus_syn_SeqInfo.txt'),('_msgfplus_syn_SeqToProteinMap.txt'),
                        ('_ScanType.txt'),('_pepXML.zip')

                End If;
            End If;
        End If;

        If _jobFileUpdateCount = 0 And Exists (Select * From Tmp_JobsToUpdate) Then
            RAISE INFO '%', 'rem Example commands for renaming job files';
        End If;

        RAISE INFO '%', '';
        RAISE INFO '%', 'cd ' || _resultsFolder;

        FOR _suffixID, _fileSuffix IN
            SELECT SuffixID, FileSuffix
            FROM Tmp_Extensions
            ORDER BY SuffixID
        LOOP
            RAISE INFO '%', 'Move ' || _datasetNameOld || _fileSuffix || ' ' || _datasetNameNew || _fileSuffix;
            _jobFileUpdateCount := _jobFileUpdateCount + 1;

        END LOOP;

        _datasetInfoFile := _datasetNameNew || '_DatasetInfo.xml'

        If _resultsFolder = 'QC' Then
            RAISE INFO '%', '';
            RAISE INFO '%', 'rem Use sed to change the dataset names in index.html';
            RAISE INFO '%', 'cat index.html | sed -r "s/' || _datasetNameOld || '/' || _datasetNameNew || '/g" > index_new.html';
            RAISE INFO '%', 'move index.html index_old.html';
            RAISE INFO '%', 'move index_new.html index.html';

            RAISE INFO '%', '';
            RAISE INFO '%', 'rem Use sed to change the dataset names in DatasetName_DatasetInfo.xml';
            RAISE INFO '%', 'cat ' || _datasetInfoFile || ' | sed -r "s/' || _datasetNameOld || '/' || _datasetNameNew || '/g" > DatasetInfo_new.xml';
            RAISE INFO '%', 'move ' || _datasetInfoFile || ' DatasetInfo_old.xml';
            RAISE INFO '%', 'move DatasetInfo_new.xml ' || _datasetInfoFile;
        End If;

        If _resultsFolder Like 'SIC%' Then
            RAISE INFO '%', '';
            RAISE INFO '%', 'rem Use sed to change the dataset names in index.html';
            RAISE INFO '%', 'cat index.html | sed -r "s/' || _datasetNameOld || '/' || _datasetNameNew || '/g" > index_new.html';
            RAISE INFO '%', 'move index.html index_old.html';
            RAISE INFO '%', 'move index_new.html index.html';
        End If;

        RAISE INFO '%', 'cd ..';

        -- Look for a MzRefinery directory for this dataset
        _mzRefineryOutputFolder := '';

        SELECT Output_Folder_Name
        INTO _mzRefineryOutputFolder
        FROM sw.T_Job_Steps
        WHERE Job = _job AND
              State <> 3 AND
              Step_Tool = 'Mz_Refinery';

        If Coalesce(_mzRefineryOutputFolder, '') <> '' Then
            RAISE INFO '%', '';
            RAISE INFO '%', 'cd ' || _mzRefineryOutputFolder;
            RAISE INFO '%', 'move ' || _datasetNameOld || '_msgfplus.mzid.gz             ' || _datasetNameNew || '_msgfplus.mzid.gz';
            RAISE INFO '%', 'move ' || _datasetNameOld || '_MZRefinery_Histograms.png    ' || _datasetNameNew || '_MZRefinery_Histograms.png';
            RAISE INFO '%', 'move ' || _datasetNameOld || '_MZRefinery_MassErrors.png    ' || _datasetNameNew || '_MZRefinery_MassErrors.png';
            RAISE INFO '%', 'move ' || _datasetNameOld || '_msgfplus.mzRefinement.tsv    ' || _datasetNameNew || '_msgfplus.mzRefinement.tsv';
            RAISE INFO '%', 'move ' || _datasetNameOld || '.mzML.gz_CacheInfo.txt        ' || _datasetNameNew || '.mzML.gz_CacheInfo.txt';
            RAISE INFO '%', '';
            RAISE INFO '%', 'rem Use sed to change the dataset name in the _CacheInfo.txt file';
            RAISE INFO '%', 'cat ' || _datasetNameNew || '.mzML.gz_CacheInfo.txt | sed -r "s/' || _datasetNameOld || '/' || _datasetNameNew || '/g" > _CacheInfo.txt.new';
            RAISE INFO '%', 'move ' || _datasetNameNew || '.mzML.gz_CacheInfo.txt ' || _datasetNameNew || '.mzML.gz_OldCacheInfo.txt';
            RAISE INFO '%', 'move _CacheInfo.txt.new ' || _datasetNameNew || '.mzML.gz_CacheInfo.txt';

            RAISE INFO '%', 'rem ToDo: rename or delete the .mzML.gz file at:';
            RAISE INFO '%', 'cat ' || _datasetNameNew || '.mzML.gz_CacheInfo.txt';
            RAISE INFO '%', 'cd ..';
        End If;

    END LOOP; -- </jobLoop>

    RAISE INFO '%', '';
    RAISE INFO '%', 'popd';
    RAISE INFO '%', '';
    RAISE INFO '%', '';

    If _jobFileUpdateCount > 0 Then
        RAISE INFO 'See the console output for % dataset/job file update commands', jobFileUpdateCount;
    End If;

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_Extensions;
    DROP TABLE Tmp_JobsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.rename_dataset IS 'RenameDataset';