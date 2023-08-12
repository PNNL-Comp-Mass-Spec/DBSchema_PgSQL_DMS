--
CREATE OR REPLACE PROCEDURE public.backfill_pipeline_jobs
(
    _infoOnly boolean = false,
    _jobsToProcess int = 0,
    _startJob int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Creates jobs in public.t_analysis_job for jobs that were originally
**      created in sw.t_jobs
**
**  Arguments:
**    _jobsToProcess   Set to a positive number to process a finite number of jobs
**    _startJob        Set to a positive number to start with the given job number (useful if we know that a job was just created in sw.t_jobs)
**
**  Auth:   mem
**  Date:   01/12/2012
**          04/10/2013 mem - Now looking up the Data Package ID using sw.V_Pipeline_Jobs_Backfill
**          01/02/2014 mem - Added support for PeptideAtlas staging jobs
**          02/27/2014 mem - Now truncating dataset name to 90 characters if too long
**          02/23/2016 mem - Add set XACT_ABORT on
**          01/31/2018 mem - Truncate dataset name at 80 characters if too long
**          07/25/2018 mem - Replace brackets with underscores
**          09/15/2020 mem - Use 'https://dms2.pnl.gov/' instead of http://
**          03/09/2021 mem - Auto change script MaxQuant_DataPkg to MaxQuant
**          03/10/2021 mem - Add argument _startJob
**          03/31/2021 mem - Expand OrganismDBName to varchar(128)
**          05/26/2021 mem - Expand _message to varchar(1024)
**          07/06/2021 mem - Extract parameter file name, protein collection list, and legacy FASTA file name from job parameters
**          08/26/2021 mem - Auto change script MSFragger_DataPkg to MSFragger
**          07/01/2022 mem - Use new parameter name for parameter file when querying V_Pipeline_Job_Parameters
**          07/29/2022 mem - Settings file names can no longer be null
**          10/04/2022 mem - Assure that auto-generated dataset names only contain alphanumeric characters (plus underscore or dash)
**          03/27/2023 mem - Auto change script DiaNN_DataPkg to DiaNN
**          06/13/2023 mem - Fix bug that used harded coded job number 1914830 instead of _job
**          08/10/2023 mem - Add user MSDADMIN to T_Users if missing
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobInfo record;
    _jobsProcessed int := 0;
    _peptideAtlasStagingTask int := 0;
    _analysisToolID int;
    _organismID Int;
    _parameterFileName text;
    _proteinCollectionList text;
    _legacyFastaFileName text;
    _datasetID int;
    _datasetComment text;
    _jobStr text;
    _dataPackageName text;
    _dataPackageFolder text;
    _storagePathRelative text;
    _mode text;
    _msg text;
    _validCh text;
    _position int;
    _numCh int;
    _ch text;
    _cleanName text;
    _callingProcName text;
    _currentLocation text := 'Start';
    _peptideAtlasStagingPathID int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);
    _jobsToProcess := Coalesce(_jobsToProcess, 0);
    _startJob := Coalesce(_startJob, 0);

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Create a temporary table to hold the job details
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Job_Backfill_Details (
        DataPackageID int NULL,
        Job int NOT NULL,
        BatchID int NULL,
        Priority int NOT NULL,
        Created timestamp NOT NULL,
        Start timestamp NULL,
        Finish timestamp NULL,
        AnalysisToolID int NOT NULL,
        ParamFileName text NOT NULL,
        SettingsFileName text NOT NULL,
        OrganismDBName text NOT NULL,
        OrganismID int NOT NULL,
        DatasetID int NOT NULL,
        Comment text NULL,
        Owner text NULL,
        StateID int NOT NULL,
        AssignedProcessorName text NULL,
        ResultsFolderName text NULL,
        ProteinCollectionList text NULL,
        ProteinOptionsList text NOT NULL,
        RequestID int NOT NULL,
        PropagationMode int NOT NULL,
        ProcessingTimeMinutes real NULL,
        Purged int NOT NULL
    );

    CREATE INDEX IX_Tmp_Job_Backfill_Details ON Tmp_Job_Backfill_Details (Job);

    If _infoOnly Then

        -- Preview all of the jobs that would be backfilled

        RAISE INFO '';

        _formatSpecifier := '%-9s %-8s %-25s %-5s %-80s %-40s %-20s %-20s %-20s %-60s %-30s %-14s %-23s %-11s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Priority',
                            'Script',
                            'State',
                            'Dataset',
                            'Results_Folder_Name',
                            'Imported',
                            'Start',
                            'Finish',
                            'Transfer_Folder_Path',
                            'Comment',
                            'Owner_Username',
                            'Processing_Time_Minutes',
                            'Data_Pkg_ID'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '--------',
                                     '-------------------------',
                                     '-----',
                                     '--------------------------------------------------------------------------------',
                                     '----------------------------------------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------',
                                     '------------------------------------------------------------',
                                     '------------------------------',
                                     '--------------',
                                     '-----------------------',
                                     '-----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT PJ.Job,
                   PJ.Priority,
                   PJ.Script,
                   PJ.State,
                   PJ.Dataset,
                   PJ.Results_Folder_Name,
                   public.timestamp_text(PJ.Imported) AS Imported,
                   public.timestamp_text(PJ.Start) AS Start,
                   public.timestamp_text(PJ.Finish) AS Finish,
                   PJ.Transfer_Folder_Path,
                   PJ.Comment,
                   PJ.Owner_Username,
                   JPT.Processing_Time_Minutes,
                   PJ.Data_Pkg_ID
            FROM sw.t_jobs PJ
                 INNER JOIN sw.t_scripts S
                   ON PJ.Script = S.Script
                 INNER JOIN sw.V_Job_Processing_Time JPT
                   ON PJ.Job = JPT.Job
                 LEFT OUTER JOIN public.T_Analysis_Job J
                   ON PJ.Job = J.job
            WHERE S.Backfill_to_DMS = 1 AND
                  PJ.Job >= _startJob AND
                  J.job IS NULL
            ORDER BY PJ.job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Priority,
                                _previewData.Script,
                                _previewData.State,
                                _previewData.Dataset,
                                _previewData.Results_Folder_Name,
                                _previewData.Imported,
                                _previewData.Start,
                                _previewData.Finish,
                                _previewData.Transfer_Folder_Path,
                                _previewData.Comment,
                                _previewData.Owner_Username,
                                _previewData.Processing_Time_Minutes,
                                _previewData.Data_Pkg_ID
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    ---------------------------------------------------
    -- Process each job present in sw.V_Pipeline_Jobs_Backfill that is not present in t_analysis_job
    ---------------------------------------------------

    FOR _jobInfo IN
        SELECT PJ.Job,
               PJ.Priority,
               PJ.Script,
               PJ.State,
               PJ.Dataset,
               PJ.Results_Folder_Name,
               PJ.Imported,
               PJ.Start,
               PJ.Finish,
               PJ.Transfer_Folder_Path As TransferFolderPath,
               PJ.Comment,
               PJ.Owner,
               JPT.ProcessingTimeMinutes,
               PJ.Data_Pkg_ID As DataPackageID
        FROM sw.t_jobs PJ
             INNER JOIN sw.t_scripts S
               ON PJ.Script = S.Script
             INNER JOIN sw.V_Job_Processing_Time JPT
               ON PJ.Job = JPT.Job
             LEFT OUTER JOIN public.T_Analysis_Job J
               ON PJ.Job = J.job
        WHERE S.Backfill_to_DMS = 1 AND
              PJ.Job >= _startJob AND
              J.job IS NULL
        ORDER BY PJ.job
    LOOP

        _jobStr := _jobInfo.Job::text;

        BEGIN

            _currentLocation := format('Validate settings required to backfill job %s', _jobStr);

            ---------------------------------------------------
            -- Lookup AnalysisToolID for _jobInfo.Script
            ---------------------------------------------------

            _analysisToolID := -1;

            If _jobInfo.Script SIMILAR TO 'MaxQuant[_]%'::citext Then
                _jobInfo.Script := 'MaxQuant';
            End If;

            If _jobInfo.Script SIMILAR TO 'MSFragger[_]%'::citext Then
                _jobInfo.Script := 'MSFragger';
            End If;

            If _jobInfo.Script SIMILAR TO 'DiaNN[_]%'::citext Then
                _jobInfo.Script := 'DiaNN';
            End If;

            SELECT analysis_tool_id
            INTO _analysisToolID
            FROM t_analysis_tool
            WHERE (analysis_tool = _jobInfo.Script);

            If Not FOUND Then
                _message := format('Script not found in t_analysis_tool: %s; unable to backfill DMS Pipeline job %s', _jobInfo.Script, _jobStr);

                If _infoOnly Then
                    RAISE INFO '%', _message;
                Else
                    CALL post_log_entry ('Error', _message, 'Backfill_Pipeline_Jobs');
                End If;

                CONTINUE;
            End If;

            If _jobInfo.Script = 'PeptideAtlas' Then
                _peptideAtlasStagingTask := 1;
            Else
                _peptideAtlasStagingTask := 0;
            End If;

            ---------------------------------------------------
            -- Lookup OrganismID for organism 'None'
            ---------------------------------------------------

            SELECT organism_id
            INTO _organismID
            FROM t_organisms
            WHERE (organism = 'None');

            If Not FOUND Then
                _message := 'organism "None" not found in t_organisms; -- this is unexpected; will set _organismID to 1'

                If _infoOnly Then
                    RAISE INFO '%', _message;
                Else
                    CALL post_log_entry ('Error', _message, 'Backfill_Pipeline_Jobs');
                End If;

                _organismID := 1;
            End If;

            ---------------------------------------------------
            -- Validate _jobInfo.Owner; update if not valid
            ---------------------------------------------------

            If Not Exists (SELECT * FROM t_users WHERE username = Coalesce(_jobInfo.Owner, '')) Then
                _jobInfo.Owner := 'H09090911';
            End If;

            ---------------------------------------------------
            -- Validate _jobInfo.State; update if not valid
            ---------------------------------------------------

            If Not Exists (SELECT * FROM t_analysis_job_state WHERE job_state_id = _jobInfo.State) Then
                _message := 'State %s not found in t_analysis_job_state; -- this is unexpected; will set _jobInfo.State to 4'; _jobInfo.State)

                If _infoOnly Then
                    RAISE INFO '%', _message;
                Else
                    CALL post_log_entry ('Error', _message, 'Backfill_Pipeline_Jobs');
                End If;

                _jobInfo.State := 4;
            End If;

            ------------------------------------------------
            -- Lookup parameter file name and protein collection, if defined
            ------------------------------------------------

            SELECT Param_Value
            INTO _parameterFileName
            FROM sw.V_Pipeline_Job_Parameters
            WHERE job = _job AND
                  Param_Name = 'ParamFileName';

            SELECT Param_Value
            INTO _proteinCollectionList
            FROM sw.V_Pipeline_Job_Parameters
            WHERE job = _job AND
                  Param_Name = 'ProteinCollectionList';

            SELECT Param_Value
            INTO _legacyFastaFileName
            FROM sw.V_Pipeline_Job_Parameters
            WHERE job = _job AND
                  Param_Name = 'LegacyFastaFileName';

            If Coalesce(_parameterFileName, '') = '' Then
                _parameterFileName := 'na';
            End If;

            If Coalesce(_proteinCollectionList, '') = '' Then
                _proteinCollectionList := 'na';
            End If;

            If Coalesce(_legacyFastaFileName, '') = '' Then
                _legacyFastaFileName := 'na';
            End If;

            ------------------------------------------------
            -- Check whether the dataset exists if it is not 'Aggregation'
            ------------------------------------------------

            _datasetID := -1;
            _datasetComment := '';

            If Coalesce(_jobInfo.Dataset, 'Aggregation') <> 'Aggregation' Then

                SELECT dataset_id
                INTO _datasetID
                FROM t_dataset
                WHERE dataset = _jobInfo.Dataset

                If Not FOUND Then
                    _datasetID := -1;
                End If

            End If;

            If _datasetID < 0 Then
            -- <c>
                ------------------------------------------------
                -- Dataset does not exist; auto-define the dataset to associate with this job
                -- First lookup the data package ID associated with this job
                ------------------------------------------------

                _currentLocation := format('Auto-define the dataset to associate with job %s', _jobStr);

                If _jobInfo.DataPackageID <= 0 Then
                    ------------------------------------------------
                    -- Job doesn't have a data package ID
                    -- Simply set _jobInfo.Dataset to DP_Aggregation
                    ------------------------------------------------
                    _jobInfo.Dataset := 'DP_Aggregation';

                Else

                    ------------------------------------------------
                    -- Lookup the Data Package name for _jobInfo.DataPackageID
                    ------------------------------------------------

                    _dataPackageName := '';
                    _dataPackageFolder := '';
                    _storagePathRelative := '';

                    SELECT Name,
                           Package_File_Folder,
                           Storage_Path_Relative
                    INTO _dataPackageName, _dataPackageFolder, _storagePathRelative
                    FROM dpkg.V_Data_Package_Export
                    WHERE ID = _jobInfo.DataPackageID;

                    If Not FOUND Or Coalesce(_dataPackageFolder, '') = '' Then
                        -- Data Package not found (or Package_File_Folder is not defined)
                        _jobInfo.Dataset := format('DataPackage_%s', _jobInfo.DataPackageID);
                    Else
                        -- Data Package found
                        _jobInfo.Dataset := format('DataPackage_%s', _dataPackageFolder);

                        If _peptideAtlasStagingTask <> 0 Then
                            _jobInfo.Dataset := format('%s_Staging', _jobInfo.Dataset);
                        End If;

                    End If;

                    _datasetComment := format('https://dms2.pnl.gov/data_package/show/%s', _jobInfo.DataPackageID)

                End If;

                If char_length(_jobInfo.Dataset) > 80 Then
                    -- Truncate the dataset name to avoid triggering an error in add_update_dataset
                    _jobInfo.Dataset := Substring(_jobInfo.Dataset, 1, 80);
                End If;

                -- Make sure there are no invalid characters in _jobInfo.Dataset
                -- Dataset names can only contain letters, underscores, or dashes (see function public.validate_chars)

                _jobInfo.Dataset := Replace(_jobInfo.Dataset, ' ', '_');

                _validCh := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
                _position := 1;
                _numCh := char_length(_jobInfo.Dataset);
                _cleanName := '';

                WHILE _position <= _numCh
                LOOP
                    _ch := SUBSTRING(_jobInfo.Dataset, _position, 1);

                    If char_length(_ch) > 0 Then
                        If Position(_ch In _validCh) = 0 Then
                            -- Invalid character
                            _cleanName := format('%s_', _cleanName);
                        Else
                            _cleanName := format('%s%s', _cleanName, _ch);
                        End If;
                    End If;

                    _position := _position + 1;
                END LOOP;

                _jobInfo.Dataset := _cleanName;

                ------------------------------------------------
                -- Now that we have constructed the name of the dataset to auto-create, see if it already exists
                ------------------------------------------------

                SELECT dataset_id
                INTO _datasetID
                FROM t_dataset
                WHERE dataset = _jobInfo.Dataset;

                If Not FOUND Then
                    _datasetID := -1;
                End If;

                If _datasetID < 0 Then
                    ------------------------------------------------
                    -- Dataset does not exist; create it
                    ------------------------------------------------

                    If Not Exists (SELECT user_id FROM t_users WHERE username = 'MSDADMIN')
                    Begin
                        -- MSDAdmin user not defined; add it

                        _currentLocation := 'Add user MSDADMIN to T_Users';

                        INSERT INTO t_users (username, name, hid, status, email, domain, payroll, active, update, comment)
                        VALUES ('MSDADMIN', 'MSDADMIN', 'H0000000', 'Active', NULL, NULL, NULL, 'Y', 'N', '');
                    End

                    _currentLocation := format('Call add_update_dataset to create dataset %s', _jobInfo.Dataset);

                    If _infoOnly Then
                        _mode := 'check_add';
                        RAISE INFO 'Check_add dataset %', _jobInfo.Dataset;
                    Else
                        _mode := 'add';
                    End If;

                    CALL add_update_dataset (
                                        _jobInfo.Dataset,       -- Dataset
                                        'DMS_Pipeline_Data',    -- Experiment
                                        'MSDADMIN',             -- Operator Username
                                        'DMS_Pipeline_Data',    -- Instrument
                                        'DataFiles',            -- Dataset Type
                                        'unknown',              -- LC Column
                                        'na',                   -- Well plate
                                        'na',                   -- Well number
                                        'none',                 -- Secondary Sep
                                        'none',                 -- Internal Standard
                                        _datasetComment,        -- Comment
                                        'Released',             -- Rating
                                        'No_Cart',              -- LC Cart
                                        '',                     -- EUS Proposal
                                        'CAP_DEV',              -- EUS Usage
                                        '',                     -- EUS Users
                                        _requestID => 0,
                                        _mode => _mode,
                                        _message => _msg,               -- Output
                                        _returnCode => _returnCode,     -- Output
                                        _aggregationJobDataset => true);

                    If _returnCode <> '' Then
                        ------------------------------------------------
                        -- Error creating dataset
                        ------------------------------------------------

                        _message := format('Error creating dataset %s for DMS Pipeline job %s', _jobInfo.Dataset, _jobStr);

                        If Coalesce(_msg, '') <> '' Then
                            _message := format('%s: %s', _message, _msg);
                        End If;

                        If _infoOnly Then
                            RAISE INFO '%', _message;
                        Else
                            CALL post_log_entry ('Error', _message, 'Backfill_Pipeline_Jobs');
                        End If;

                        _datasetID := -1;
                    Else
                        ------------------------------------------------
                        -- Dataset found
                        ------------------------------------------------

                        If _infoOnly Then
                            _datasetID := 1;
                        Else
                            ------------------------------------------------
                            -- Determine the DatasetID for the newly-created dataset
                            ------------------------------------------------

                            _currentLocation := format('Determine DatasetID for newly created dataset %s', _jobInfo.Dataset);

                            SELECT dataset_id
                            INTO _datasetID
                            FROM t_dataset
                            WHERE dataset = _jobInfo.Dataset;

                            If Not FOUND Then
                                _message := format('Error creating dataset %s for DMS Pipeline job %s; call to add_update_dataset succeeded but dataset not found in t_dataset',
                                                    _jobInfo.Dataset, _jobStr);

                                CALL post_log_entry ('Error', _message, 'Backfill_Pipeline_Jobs');

                                _datasetID := -1;
                            End If;

                            If Coalesce(_storagePathRelative, '') <> '' Then
                                If _peptideAtlasStagingTask <> 0 Then
                                    -- The data files will be stored at a path of the form:
                                    --   \\protoapps\PeptideAtlas_Staging\829_Organelle_Targeting_ABPP
                                    -- Need to determine the path ID

                                    SELECT storage_path_id
                                    INTO _peptideAtlasStagingPathID
                                    FROM t_storage_path
                                    WHERE (storage_path IN ('PeptideAtlas_Staging', 'PeptideAtlas_Staging\'))

                                    If Coalesce(_peptideAtlasStagingPathID, 0) > 0 Then
                                        UPDATE t_dataset
                                        SET storage_path_ID = _peptideAtlasStagingPathID
                                        WHERE dataset_id = _datasetID

                                        _storagePathRelative := _dataPackageFolder;
                                    End If;
                                End If;

                                -- Update the Dataset Folder for the newly-created dataset
                                UPDATE t_dataset
                                SET folder_name = _storagePathRelative
                                WHERE dataset_id = _datasetID
                            End If;

                        End If;

                    End If;

                End If;

                If _datasetID > 0 Then
                    ------------------------------------------------
                    -- Dataset is now defined for job to backfill
                    -- Add a new row to Tmp_Job_Backfill_Details
                    ------------------------------------------------

                    _currentLocation := format('Add job %s to Tmp_Job_Backfill_Details', _jobStr);

                    INSERT INTO Tmp_Job_Backfill_Details
                            (DataPackageID, Job, BatchID, Priority, Created, Start, Finish, AnalysisToolID,
                            ParamFileName, SettingsFileName, OrganismDBName, OrganismID, DatasetID, Comment, Owner,
                            StateID, AssignedProcessorName, ResultsFolderName, ProteinCollectionList, ProteinOptionsList,
                            RequestID, PropagationMode, ProcessingTimeMinutes, Purged)
                    SELECT _jobInfo.DataPackageID,
                           _jobInfo.Job,
                           0,                               -- BatchID
                           _jobInfo.Priority,               -- Priority
                           _jobInfo.Imported,               -- Created
                           _jobInfo.Start,                  -- Start
                           _jobInfo.Finish,                 -- Finish
                           _analysisToolID,                 -- AnalysisToolID
                           _parameterFileName,              -- ParamFileName
                           'na',                            -- SettingsFileName
                           _legacyFastaFileName,            -- OrganismDBName
                           _organismID,                     -- OrganismID
                           _datasetID,                      -- DatasetID
                           Coalesce(_jobInfo.Comment, ''),  -- Comment
                           _jobInfo.Owner,                  -- Owner
                           _jobInfo.State,                  -- StateID
                           'Job_Broker',                    -- AssignedProcessorName
                           _jobInfo.Results_Folder_Name,    -- ResultsFolderName
                           _proteinCollectionList,          -- ProteinCollectionList
                           'na',                            -- ProteinOptionsList
                           1,                               -- RequestID
                           0,                               -- PropagationMode
                           _jobInfo.ProcessingTimeMinutes,  -- ProcessingTimeMinutes
                           0);                              -- Purged

                    If Not _infoOnly Then
                        ------------------------------------------------
                        -- Append the job to t_analysis_job
                        ------------------------------------------------

                        _currentLocation := format('Add job %s to t_analysis_job using Tmp_Job_Backfill_Details', _jobStr);

                        INSERT INTO t_analysis_job ( job, batch_id, priority, created, start, finish, analysis_tool_id,
                                                     param_file_name, settings_file_name, organism_db_name, organism_id, dataset_id, comment, owner_username,
                                                     job_state_id, assigned_processor_name, results_folder_name, protein_collection_list, protein_options_list,
                                                     request_id, propagation_mode, processing_time_minutes, purged )
                        SELECT job, BatchID, priority, created, Start, Finish, AnalysisToolID,
                            ParamFileName, SettingsFileName, OrganismDBName, OrganismID, DatasetID, comment, owner,
                            StateID, AssignedProcessorName, ResultsFolderName, ProteinCollectionList, ProteinOptionsList,
                            RequestID, PropagationMode, ProcessingTimeMinutes, purged
                        FROM Tmp_Job_Backfill_Details
                        WHERE job = _jobInfo.Job;

                        If Not FOUND Then
                            _message := format('Error adding DMS Pipeline job %s to t_analysis_job', _jobStr);
                            CALL post_log_entry ('Error', _message, 'Backfill_Pipeline_Jobs');
                        End If;

                    End If;

                End If;

            End If;

        EXCEPTION
            -- Error caught; log the error then continue with the next job to backfill
            --
            WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS
                    _sqlState         = returned_sqlstate,
                    _exceptionMessage = message_text,
                    _exceptionDetail  = pg_exception_detail,
                    _exceptionContext = pg_exception_context;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);

            If Coalesce(_returnCode, '') = '' Then
                _returnCode := _sqlState;
            End If;

        END;

        _jobsProcessed := _jobsProcessed + 1;

        If _jobsToProcess > 0 And _jobsProcessed >= _jobsToProcess Then
            -- Break out of the For loop
            EXIT;
        End If;

    END LOOP;


    If _infoOnly Then
        ------------------------------------------------
        -- Preview the new jobs
        ------------------------------------------------

        SELECT *
        FROM Tmp_Job_Backfill_Details
        ORDER BY Job
    Else
    -- <f>

        BEGIN

            ------------------------------------------------
            -- Use a Merge query to update backfilled jobs where Start, Finish, State, or ProcessingTimeMinutes has changed
            -- Do not change a job from State 14 to a State > 4
            ------------------------------------------------

            _currentLocation := 'Synchronize t_analysis_job with back-filled jobs from sw.t_jobs';

            MERGE INTO t_analysis_job AS target
            USING ( SELECT PJ.job,
                           PJ.priority,
                           PJ.State,
                           PJ.start,
                           PJ.finish,
                           PJ.processing_time_minutes
                    FROM sw.V_Pipeline_Jobs_Backfill PJ
                  ) AS Source
            ON (target.job = source.job)
            WHEN MATCHED AND
                 (target.job_state_id <> 14 AND target.job_state_id <> source.State OR
                  target.priority <> source.priority OR
                  target.start IS DISTINCT FROM source.start OR
                  target.finish IS DISTINCT FROM source.finish OR
                  target.processing_time_minutes IS DISTINCT FROM source.processing_time_minutes) THEN
                UPDATE SET
                    job_state_id = CASE WHEN Target.job_state_id = 14 Then 14 Else source.State End,
                    priority = source.priority,
                    start = source.start,
                    finish = source.finish,
                    processing_time_minutes = source.ProcessingTimeMinutes
            ;

        EXCEPTION
            -- Error caught; log the error then continue with the next job to backfill
            --
            WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS
                    _sqlState         = returned_sqlstate,
                    _exceptionMessage = message_text,
                    _exceptionDetail  = pg_exception_detail,
                    _exceptionContext = pg_exception_context;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);

            If Coalesce(_returnCode, '') = '' Then
                _returnCode := _sqlState;
            End If;
        END;

    END LOOP;

    DROP TABLE IF EXISTS Tmp_Job_Backfill_Details;
END
$$;

COMMENT ON PROCEDURE public.backfill_pipeline_jobs IS 'BackfillPipelineJobs';
