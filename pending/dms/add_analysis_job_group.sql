
CREATE OR REPLACE PROCEDURE public.add_analysis_job_group
(
    _datasetList text,
    _priority int = 2,
    _toolName text,
    _paramFileName text,
    _settingsFileName text,
    _organismDBName text,
    _organismName text,
    _protCollNameList text,
    _protCollOptionsList text,
    _ownerUsername text,
    _comment text = null,
    _specialProcessing text = null,
    _requestID int,
    _dataPackageID int = 0,
    _associatedProcessorGroup text = '',
    _propagationMode text = 'Export',
    _removeDatasetsWithJobs text = 'Y',
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new analysis jobs for list of datasets
**
**  Arguments:
**    _datasetList                  Comma-separated list of dataset names; ignored if _dataPackageID is a positive integer
**    _priority                     Job priority (1 means highest priority)
**    _toolName                     Analysis tool name
**    _paramFileName                Parameter file name
**    _settingsFileName             Settings file name
**    _organismDBName               Legacy FASTA name; 'na' if using protein collections
**    _organismName                 Organism name
**    _protCollNameList             Comma-separated list of protein collection names
**    _protCollOptionsList          Protein collection options
**    _ownerUsername                Owner username; will be updated to _callingUser if _callingUser is valid
**    _comment                      Job comment
**    _specialProcessing            Special processing parameters
**    _requestID                    0 if not associated with a request; otherwise, request ID in t_analysis_job_request
**    _dataPackageID                Data package ID
**    _associatedProcessorGroup     Processor group name; deprecated in May 2015
**    _propagationMode              Propagation mode: 'Export', 'No Export'
**    _removeDatasetsWithJobs       If 'N' or 'No', do not remove datasets with existing jobs (ignored if _dataPackageID is non-zero)
**    _mode                         Mode: 'add' or 'preview'
**    _message                      Output message
**    _returnCode                   Return code
**    _callingUser                  Calling user username
**
**  Auth:   grk
**  Date:   01/29/2004
**          04/01/2004 grk - Fixed error return
**          06/07/2004 to 4/04/2006 -- multiple updates
**          04/05/2006 grk - Major rewrite
**          04/10/2006 grk - Widened size of list argument to 6000 characters
**          11/30/2006 mem - Added column Dataset_Type to Tmp_DatasetInfo (Ticket #335)
**          12/19/2006 grk - Added propagation mode (Ticket #348)
**          12/20/2006 mem - Added column dataset_rating_id to Tmp_DatasetInfo (Ticket #339)
**          02/07/2007 grk - Eliminated 'Spectra Required' states (Ticket #249)
**          02/15/2007 grk - Added associated processor group (Ticket #383)
**          02/21/2007 grk - Removed _assignedProcessor  (Ticket #383)
**          10/11/2007 grk - Expand protein collection list size to 4000 characters (https://prismtrac.pnl.gov/trac/ticket/545)
**          02/19/2008 grk - Add explicit NULL column attribute to Tmp_DatasetInfo
**          02/29/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user or alter_event_log_entry_user_multi_id (Ticket #644)
**          05/27/2008 mem - Increased _entryTimeWindowSeconds value to 45 seconds when calling alter_event_log_entry_user_multi_id
**          09/12/2008 mem - Now passing _paramFileName and _settingsFileName ByRef to Validate_Analysis_Job_Parameters (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**          02/27/2009 mem - Expanded _comment to varchar(512)
**          04/15/2009 grk - Handles wildcard DTA folder name in comment field (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          08/05/2009 grk - Assign job number from separate table (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**          08/05/2009 mem - Now removing duplicates when populating Tmp_DatasetInfo
**                         - Updated to use get_new_job_id_block to obtain job numbers
**          09/17/2009 grk - Don't make new jobs for datasets with existing jobs (optional mode) (Ticket #747, http://prismtrac.pnl.gov/trac/ticket/747)
**          09/19/2009 grk - Improved return message
**          09/23/2009 mem - Updated to handle requests with state "New (Review Required)"
**          12/21/2009 mem - Now updating field job_count in T_Analysis_Job_Request when _requestID is > 1
**          04/22/2010 grk - Use try-catch for error handling
**          05/05/2010 mem - Now passing _ownerUsername to Validate_Analysis_Job_Parameters as input/output
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          01/31/2011 mem - Expanded _datasetList to varchar(max)
**          02/24/2011 mem - No longer skipping jobs with state 'No Export' when finding datasets that have existing, matching jobs
**          03/29/2011 grk - Added _specialProcessing argument (http://redmine.pnl.gov/issues/304)
**          05/24/2011 mem - Now populating column dataset_unreviewed
**          06/15/2011 mem - Now ignoring organism, protein collection, and organism DB when looking for existing jobs and the analysis tool does not use an organism database
**          09/25/2012 mem - Expanded _organismDBName and _organismName to varchar(128)
**          11/08/2012 mem - Now auto-updating _protCollOptionsList to have 'seq_direction=forward' if it contains 'decoy' and the search tool is MSGFPlus (MSGFDB) and the parameter file does not contain 'NoDecoy'
**          01/11/2013 mem - Renamed MSGF-DB search tool to MSGFPlus
**          03/26/2013 mem - Now calling alter_event_log_entry_user after updating T_Analysis_Job_Request
**          03/27/2013 mem - Now auto-updating _ownerUsername to _callingUser if _callingUser maps to a valid user
**          06/06/2013 mem - Now setting job state to 19="Special Proc. Waiting" if analysis tool has Use_SpecialProcWaiting enabled
**          04/08/2015 mem - Now passing _autoUpdateSettingsFileToCentroided and _warning to Validate_Analysis_Job_Parameters
**          05/28/2015 mem - No longer creating processor group entries (thus _associatedProcessorGroup is ignored)
**          12/17/2015 mem - Now considering _specialProcessing when looking for existing jobs
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          05/18/2016 mem - Include the Request ID in error messages
**          07/12/2016 mem - Pass _priority to Validate_Analysis_Job_Parameters
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2017 mem - Set _allowNewDatasets to false when calling Validate_Analysis_Job_Parameters
**          05/11/2018 mem - When the settings file is Decon2LS_DefSettings.xml, also match jobs with a settings file of 'na'
**          06/12/2018 mem - Send _maxLength to append_to_text
**          07/30/2019 mem - Call Update_Cached_Job_Request_Existing_Jobs after creating new jobs
**          03/10/2021 mem - Add _dataPackageID
**          03/11/2021 mem - Associate new pipeline-based jobs with their analysis job request
**          03/15/2021 mem - Read setting CacheFolderRootPath from MaxQuant settings files
**                         - Update settings file, parameter file, protein collection, etc. in T_Analysis_Job for newly created MaxQuant jobs
**          03/16/2021 mem - Add check for MSXMLGenerator being 'skip'
**          06/01/2021 mem - Raise an error if _mode is invalid
**          08/26/2021 mem - Add support for data package based MSFragger jobs
**          11/15/2021 mem - Use custom messages when creating a single job
**          02/02/2022 mem - Include the settings file name in the job parameters when creating a data package based job
**          02/12/2022 mem - Add MSFragger job parameters to the settings for data package based MSFragger jobs
**          02/18/2022 mem - Add MSFragger DatabaseSplitCount to the settings for data package based MSFragger jobs
**          03/03/2022 mem - Add support for MSFragger options AutoDefineExperimentGroupWithDatasetName and AutoDefineExperimentGroupWithExperimentName
**          03/17/2022 mem - Log errors only after parameters have been validated
**          06/30/2022 mem - Rename parameter file argument
**          07/01/2022 mem - Rename auto generated parameters to use ParamFileName and ParamFileStoragePath
**          07/29/2022 mem - Assure that the parameter file and settings file names are not null
**          03/22/2023 mem - Add support for data package based DIA-NN jobs
**                         - For data package based jobs, convert every settings file setting to XML compatible with add_update_local_job_in_broker
**          03/27/2023 mem - Synchronize protein collection options validation with add_update_analysis_job_request
**                         - Remove dash from DiaNN tool name
**          07/27/2023 mem - Update message sent to get_new_job_id()
**          09/06/2023 mem - Remove leading space from messages
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _deleteCount int;
    _list text;
    _jobID int;
    _jobIDStart int;
    _jobIDEnd int;
    _jobStateID int;
    _requestStateID int := 0;
    _jobCountToBeCreated int := 0;
    _msgForLog text;
    _logErrors boolean := false;
    _gid int;
    _newUsername text;
    _slashIndex int;
    _datasetCountToRemove int := 0;
    _removedDatasetsMsg text := '';
    _removedDatasets text := '';
    _propMode int;
    _userID int;
    _analysisToolID int;
    _organismID int;
    _warning text := '';
    _paramFileStoragePath text;
    _createMzMLFilesFlag text := 'False';
    _msXmlGenerator text := '';
    _msXMLOutputType text := '';
    _centroidMSXML text := '';
    _centroidPeakCountToRetain text := '';
    _cacheFolderRootPath text := '';
    _msFraggerJavaMemorySize text := '';
    _databaseSplitCount text := '';
    _matchBetweenRuns text := '';
    _autoDefineExperimentGroupWithDatasetName text := '';
    _autoDefineExperimentGroupWithExperimentName text := '';
    _runPeptideProphet text := '';
    _runProteinProphet text := '';
    _runPercolator text := '';
    _generatePeptideLevelSummary text := '';
    _generateProteinLevelSummary text := '';
    _ms1QuantDisabled text := '';
    _runFreeQuant text := '';
    _runIonQuant text := '';
    _reporterIonMode text := '';
    _featureDetectionMZTolerance text := '';
    _featureDetectionRTTolerance text := '';
    _mbrMinimumCorrelation text := '';
    _mbrRTTolerance text := '';
    _mbrIonFdr text := '';
    _mbrPeptideFdr text := '';
    _mbrProteinFdr text := '';
    _normalizeIonIntensities text := '';
    _minIonsForProteinQuant text := '';
    _pipelineJob int;
    _resultsDirectoryName text;
    _sectionName text;
    _keyName text;
    _value text;
    _jobParam text;
    _scriptName text := 'Undefined_Script';
    _batchID int := 0;
    _numDatasets int := 0;
    _createdSettingsFileValuesTable boolean := false;
    _createdNewJobIDsTable boolean := false;
    _alterEnteredByMessage text;

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

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _requestID     := Coalesce(_requestID, 0);
        _dataPackageID := Coalesce(_dataPackageID, 0);
        _datasetList   := Trim(Coalesce(_datasetList, ''));
        _mode          := Trim(Lower(Coalesce(_mode, '')));

        If _dataPackageID < 0 Then
            _dataPackageID := 0;
        End If;

        If Not _mode In ('add', 'preview') Then
            RAISE EXCEPTION 'Invalid mode: should be "add" or "preview", not "%"', _mode;
        End If;

        ---------------------------------------------------
        -- We either need datasets or a data package
        ---------------------------------------------------

        If _dataPackageID > 0 Then
            _datasetList := '';
        ElsIf _datasetList = ''
            _message := format('Dataset list is empty for request %s', _requestID);
            RAISE EXCEPTION '%', _message;
        End If;

        _paramFileName := Trim(Coalesce(_paramFileName, ''));
        _settingsFileName := Trim(Coalesce(_settingsFileName, ''));

        /*
        ---------------------------------------------------
        -- Deprecated in May 2015: resolve processor group ID
        ---------------------------------------------------

        _gid := 0;

        If _associatedProcessorGroup <> '' Then
            SELECT group_id
            INTO _gid
            FROM t_analysis_job_processor_group
            WHERE group_name = _associatedProcessorGroup;

            If _gid = 0 Then
                RAISE EXCEPTION 'Processor group name not found for request %', _requestID;
            End If;
        End If;
        */

        ---------------------------------------------------
        -- Create temporary table to hold list of datasets
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetInfo (
            Dataset_Name citext,
            Dataset_ID int NULL,
            Instrument_Class text NULL,
            Dataset_State_ID int NULL,
            Archive_State_ID int NULL,
            Dataset_Type text NULL,
            Dataset_Rating_ID smallint NULL,
            Job int NULL,
            Dataset_Unreviewed int NULL
        );

        CREATE INDEX IX_Tmp_DatasetInfo_Dataset_Name ON Tmp_DatasetInfo (Dataset_Name);

        If _dataPackageID > 0 Then
            If Not _toolName::citext In ('MaxQuant', 'MSFragger', 'DiaNN') Then
                _message := format('%s is not a compatible tool for job requests with a data package; the only supported tools are MaxQuant, MSFragger, and DiaNN', _toolName);
                RAISE EXCEPTION '%', _message;
            End If;

            If _requestID <= 0 Then
                _message := 'Data-package based jobs must be associated with an analysis job request';
                RAISE EXCEPTION '%', _message;
            End If;

            ---------------------------------------------------
            -- Populate table using the datasets currently associated with the data package
            -- Remove any duplicates that may be present
            ---------------------------------------------------

            INSERT INTO Tmp_DatasetInfo ( Dataset_Name )
            SELECT DISTINCT Dataset
            FROM dpkg.v_data_package_dataset_export
            WHERE Data_Package_ID = _dataPackageID;

            If Not Found Then
                _message := 'Data package does not have any datasets associated with it';
                RAISE EXCEPTION '%', _message;
            End If;
        Else
            ---------------------------------------------------
            -- Populate table from dataset list
            -- Using Select Distinct to make sure any duplicates are removed
            ---------------------------------------------------

            INSERT INTO Tmp_DatasetInfo (Dataset_Name)
            SELECT DISTINCT Trim(Value)
            FROM public.parse_delimited_list(_datasetList);
            --
            GET DIAGNOSTICS _jobCountToBeCreated = ROW_COUNT;

            -- Make sure the Dataset names do not have carriage returns or line feeds

            UPDATE Tmp_DatasetInfo
            SET Dataset_Name = Replace(Dataset_Name, chr(13), '')
            WHERE Dataset_Name LIKE '%' || chr(13) || '%';

            UPDATE Tmp_DatasetInfo
            SET Dataset_Name = Replace(Dataset_Name, chr(10), '')
            WHERE Dataset_Name LIKE '%' || chr(10) || '%';
        End If;

        ---------------------------------------------------
        -- Assure that we are not running a decoy search if using MSGFPlus, TopPIC, or MaxQuant (since those tools auto-add decoys)
        -- However, if the parameter file contains _NoDecoy in the name, we'll allow _protCollOptionsList to contain Decoy
        ---------------------------------------------------

        If (_toolName ILike 'MSGFPlus%' Or _toolName ILike 'TopPIC%' Or _toolName ILike 'MaxQuant%' Or _toolName ILike 'DiaNN%') And
           _protCollOptionsList ILike '%decoy%' And
           Not _paramFileName ILike '%_NoDecoy%' Then

            _protCollOptionsList := 'seq_direction=forward,filetype=fasta';

            If Coalesce(_message, '') = '' And _toolName ILike 'MSGFPlus%' Then
                _message := 'Note: changed protein options to forward-only since MS-GF+ parameter files typically have tda=1';
            End If;

            If Coalesce(_message, '') = '' And _toolName ILike 'TopPIC%' Then
                _message := 'Note: changed protein options to forward-only since TopPIC parameter files typically have Decoy=True';
            End If;

            If Coalesce(_message, '') = '' And _toolName ILike 'MaxQuant%' Then
                _message := 'Note: changed protein options to forward-only since MaxQuant parameter files typically have <decoyMode>revert</decoyMode>';
            End If;

            If Coalesce(_message, '') = '' And _toolName ILike 'DiaNN%' Then
                _message := 'Note: changed protein options to forward-only since DiaNN expects the FASTA file to not have decoy proteins';
            End If;
        End If;

        ---------------------------------------------------
        -- Assure that we are running a decoy search if using MODa or MSFragger
        -- However, if the parameter file contains _NoDecoy in the name, we'll allow @protCollOptionsList to contain Decoy
        ---------------------------------------------------

        If (_toolName ILike 'MODa%' Or _toolName ILike 'MSFragger%') And _protCollOptionsList ILike '%forward%' And Not _paramFileName ILike '%_NoDecoy%' Then
            _protCollOptionsList := 'seq_direction=decoy,filetype=fasta';

            If Coalesce(_message, '') = '' Then
                _message := format('Note: changed protein options to decoy-mode since %s expects the FASTA file to have decoy proteins', _toolName);
            End If;
        End If;

        ---------------------------------------------------
        -- Auto-update _ownerUsername to _callingUser if possible
        ---------------------------------------------------

        If char_length(_callingUser) > 0 Then

            _newUsername := _callinguser;

            _slashIndex := Position('\' In _newUsername);

            If _slashIndex > 0 Then
                _newUsername := SUBSTRING(_newUsername, _slashIndex + 1, char_length(_newUsername));
            End If;

            If Exists (SELECT username FROM t_users WHERE username = _newUsername) Then
                _ownerUsername := _newUsername;
            End If;
        End If;

        ---------------------------------------------------
        -- If _removeDatasetsWithJobs is not 'N',
        -- find datasets from temp table that have existing
        -- jobs that match criteria from request
        --
        -- If AJT_orgDbReqd = 0, we ignore organism, protein collection, and organism DB
        ---------------------------------------------------

        If _dataPackageID = 0 And _removeDatasetsWithJobs::citext Not In ('N', 'No') Then

            CREATE TEMP TABLE Tmp_MatchingJobDatasets (
                Dataset text
            );

            INSERT INTO Tmp_MatchingJobDatasets (dataset)
            SELECT DS.dataset AS Dataset
            FROM t_dataset DS
                 INNER JOIN t_analysis_job AJ
                   ON AJ.dataset_id = DS.dataset_id
                 INNER JOIN t_analysis_tool AJT
                   ON AJ.analysis_tool_id = AJT.analysis_tool_id
                 INNER JOIN t_organisms Org
                   ON AJ.organism_id = Org.organism_id
                 -- INNER JOIN t_analysis_job_state AJS
                 --  ON AJ.job_state_id = AJS.job_state_id
                 INNER JOIN Tmp_DatasetInfo
                   ON Tmp_DatasetInfo.dataset = DS.dataset
            WHERE NOT AJ.job_state_id IN (5) AND
                  AJT.analysis_tool = _toolName::citext AND
                  AJ.param_file_name = _paramFileName::citext AND
                  ( AJ.settings_file_name = _settingsFileName::citext OR
                    AJ.settings_file_name = 'na' AND
                    _settingsFileName::citext = 'Decon2LS_DefSettings.xml'
                  )
                  AND
                  (
                    ( _protCollNameList::citext = 'na' AND
                      AJ.organism_db_name = _organismDBName::citext AND
                      Org.organism = Coalesce(_organismName::citext, Org.organism)
                    )
                    OR
                    ( _protCollNameList::citext <> 'na' AND
                      AJ.protein_collection_list = Coalesce(_protCollNameList::citext, AJ.protein_collection_list) AND
                      AJ.protein_options_list = Coalesce(_protCollOptionsList::citext, AJ.protein_options_list)
                    )
                    OR
                    AJT.org_db_required = 0
                  )
                  AND
                  Coalesce(AJ.special_processing, '') = Coalesce(_specialProcessing::citext, '')
            GROUP BY DS.dataset;
            --
            GET DIAGNOSTICS _datasetCountToRemove = ROW_COUNT;

            If _datasetCountToRemove > 0 Then

                -- Remove datasets from list that have existing jobs
                --
                DELETE FROM Tmp_DatasetInfo
                WHERE Dataset_Name IN (SELECT Dataset FROM Tmp_MatchingJobDatasets);
                --
                GET DIAGNOSTICS _deleteCount = ROW_COUNT;

                _jobCountToBeCreated := _jobCountToBeCreated - _deleteCount;

                -- Construct message of removed dataset(s)
                --
                _removedDatasetsMsg := format('Skipped %s %s existing jobs',
                                              _datasetCountToRemove,
                                              public.check_plural(_datasetCountToRemove, 'dataset that has', 'datasets that have'));

                SELECT string_agg(Dataset, ', ' ORDER BY Dataset)
                INTO _removedDatasets
                FROM Tmp_MatchingJobDatasets;

                _removedDatasetsMsg := format('%s: %s', _removedDatasetsMsg, _removedDatasets);

                If _datasetCountToRemove > 5 Then
                    _removedDatasets := format('%s (more datasets not shown)', _removedDatasets);
                End If;
            End If;

            DROP TABLE Tmp_MatchingJobDatasets;
        End If;

        ---------------------------------------------------
        -- Resolve propagation mode
        ---------------------------------------------------
        _propMode := CASE _propagationMode::citext
                         WHEN 'Export' THEN 0
                         WHEN 'No Export' THEN 1
                         ELSE 0
                     END;

        ---------------------------------------------------
        -- Validate job parameters
        ---------------------------------------------------

        _organismName := Trim(_organismName);

        CALL public.validate_analysis_job_parameters (
                                _toolName => _toolName,
                                _paramFileName => _paramFileName,               -- Output
                                _settingsFileName => _settingsFileName,         -- Output
                                _organismDBName => _organismDBName,             -- Output
                                _organismName => _organismName,
                                _protCollNameList => _protCollNameList,         -- Output
                                _protCollOptionsList => _protCollOptionsList,   -- Output
                                _ownerUsername => _ownerUsername,               -- Output
                                _mode => _mode,
                                _userID => _userID,                             -- Output
                                _analysisToolID => _analysisToolID,             -- Output
                                _organismID => _organismID,                     -- Output
                                _job => 0,
                                _autoRemoveNotReleasedDatasets => false,
                                _autoUpdateSettingsFileToCentroided => true,
                                _allowNewDatasets => false,
                                _warning => _warning,                           -- Output
                                _priority => _priority,                         -- Output
                                _showDebugMessages => false,
                                _message => _message,                           -- Output
                                _returnCode => _returnCode);                    -- Output


        If _returnCode <> '' Then
            RAISE EXCEPTION 'Validate_Analysis_Job_Parameters: % for request % (code %)', _message, _requestID, _returnCode;
        End If;

        If Coalesce(_warning, '') <> '' Then
            _comment := public.append_to_text(_comment, _warning, _delimiter => '; ', _maxlength => 512);
        End If;

        ---------------------------------------------------
        -- New jobs typically have state 1
        -- Update _jobStateID to 19="Special Proc. Waiting" if necessary
        ---------------------------------------------------

        _jobStateID := 1;

        If Coalesce(_specialProcessing, '') <> '' And Exists
           (SELECT analysis_tool_id FROM t_analysis_tool WHERE analysis_tool = _toolName::citext AND use_special_proc_waiting > 0) Then

            _jobStateID := 19;

        End If;

        ---------------------------------------------------
        -- Populate the Dataset_Unreviewed column in Tmp_DatasetInfo
        ---------------------------------------------------

        UPDATE Tmp_DatasetInfo
        SET Dataset_Unreviewed = CASE WHEN DS.dataset_rating_id = -10 THEN 1 ELSE 0 END
        FROM t_dataset DS
            INNER JOIN Tmp_DatasetInfo
            ON DS.dataset = Tmp_DatasetInfo.dataset

        If _dataPackageID > 0 Then
            If _mode = 'add' Then
                ---------------------------------------------------
                -- Make sure the job request is in state 1=new or state 5=new (Review Required)
                ---------------------------------------------------

                SELECT request_state_id
                INTO _requestStateID
                FROM t_analysis_job_request
                WHERE request_id = _requestID;

                _requestStateID := Coalesce(_requestStateID, 0);

                If Not _requestStateID In (1, 5) Then
                    -- Request ID is non-zero and request is not in state 1 or state 5
                    RAISE EXCEPTION 'Request is not in state New; cannot create an aggregation job for request %', _requestID;
                End If;
            End If;

            _logErrors := true;

            If _toolName::citext In ('MaxQuant', 'MSFragger', 'DiaNN') Then

                SELECT param_file_storage_path
                INTO _paramFileStoragePath
                FROM t_analysis_tool
                WHERE analysis_tool = _toolName::citext;

                If Not FOUND Then
                    RAISE EXCEPTION 'Tool % not found in t_analysis_tool', _toolName;
                End If;

                CREATE TEMP TABLE Tmp_SettingsFile_Values_DataPkgJob (
                    Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                    SectionName text NULL,
                    KeyName text NULL,
                    Value text NULL
                );

                _createdSettingsFileValuesTable := true;

                -- Populate the temporary Table by parsing the XML in the contents column of table t_settings_files
                --
                INSERT INTO Tmp_SettingsFile_Values_DataPkgJob (SectionName, KeyName, Value)
                SELECT XmlQ.section, XmlQ.name, XmlQ.value
                FROM (
                    SELECT xmltable.*
                    FROM ( SELECT contents As settings
                           FROM t_settings_files
                           WHERE file_name = _settingsFileName::citext AND analysis_tool = _toolName::citext
                         ) Src,
                         XMLTABLE('//sections/section/item'
                                  PASSING Src.settings
                                  COLUMNS section citext PATH '../@name',
                                          name    citext PATH '@key',
                                          value   citext PATH '@value'
                                          )
                     ) XmlQ;

                SELECT Value
                INTO _msXmlGenerator
                FROM Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MSXMLGenerator'

                SELECT Value
                INTO _msXMLOutputType
                FROM Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MSXMLOutputType'

                SELECT Value
                INTO _centroidMSXML
                FROM Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'CentroidMSXML'

                SELECT Value
                INTO _centroidPeakCountToRetain
                FROM Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'CentroidPeakCountToRetain'

                SELECT Value
                INTO _cacheFolderRootPath
                FROM Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'CacheFolderRootPath'

                If char_length(_msXmlGenerator) > 0 And char_length(_msXMLOutputType) > 0 And _msXmlGenerator <> 'skip' Then
                    _createMzMLFilesFlag := 'True';
                End If;

                If char_length(_cacheFolderRootPath) = 0 Then
                    RAISE EXCEPTION '% settings file is missing parameter CacheFolderRootPath', _toolName;
                End If;

                ---------------------------------------------------
                -- Add (or preview) a new aggregation job for data package _dataPackageID
                ---------------------------------------------------

                _pipelineJob := 0;
                _resultsDirectoryName = '';

                 -- Note that the parameters defined here need to stay in sync with the parameters in the 'SELECT SectionName, KeyName, Value FROM Tmp_SettingsFile_Values_DataPkgJob' query below
                 --
                _jobParam :=
                   format('<Param Section="JobParameters" Name="CreateMzMLFiles" Value="%s" />',            _createMzMLFilesFlag)       ||
                   format('<Param Section="JobParameters" Name="DatasetName" Value="Aggregation" />')                                   ||
                   format('<Param Section="JobParameters" Name="CacheFolderRootPath" Value="%s" />',        _cacheFolderRootPath)       ||
                   format('<Param Section="JobParameters" Name="SettingsFileName" Value="%s" />',           _settingsFileName)          ||
                   format('<Param Section="MSXMLGenerator" Name="MSXMLGenerator" Value="%s" />',            _msXmlGenerator)            ||
                   format('<Param Section="MSXMLGenerator" Name="MSXMLOutputType" Value="%s" />',           _msXMLOutputType)           ||
                   format('<Param Section="MSXMLGenerator" Name="CentroidMSXML" Value="%s" />',             _centroidMSXML)             ||
                   format('<Param Section="MSXMLGenerator" Name="CentroidPeakCountToRetain" Value="%s" />', _centroidPeakCountToRetain) ||
                   format('<Param Section="PeptideSearch" Name="ParamFileName" Value="%s" />',              _paramFileName)             ||
                   format('<Param Section="PeptideSearch" Name="ParamFileStoragePath" Value="%s" />',       _paramFileStoragePath)      ||
                   format('<Param Section="PeptideSearch" Name="OrganismName" Value="%s" />',               _organismName)              ||
                   format('<Param Section="PeptideSearch" Name="ProteinCollectionList" Value="%s" />',      _protCollNameList)          ||
                   format('<Param Section="PeptideSearch" Name="ProteinOptions" Value="%s" />',             _protCollOptionsList)       ||
                   format('<Param Section="PeptideSearch" Name="LegacyFastaFileName" Value="%s" />',        _organismDBName);

                -- Append the additional settings defined in the settings file

                FOR _sectionName, _keyName, _value IN
                    SELECT SectionName,
                           KeyName,
                           Value
                    FROM Tmp_SettingsFile_Values_DataPkgJob
                    WHERE NOT (SectionName = 'JobParameters'  AND KeyName IN ('CreateMzMLFiles', 'DatasetName', 'CacheFolderRootPath', 'SettingsFileName')) AND
                          NOT (SectionName = 'MSXMLGenerator' AND KeyName IN ('MSXMLGenerator', 'MSXMLOutputType', 'CentroidMSXML', 'CentroidPeakCountToRetain')) AND
                          NOT (SectionName = 'PeptideSearch'  AND KeyName IN ('ParamFileName', 'ParamFileStoragePath', 'OrganismName', 'ProteinCollectionList', 'ProteinOptions', 'LegacyFastaFileName'))
                    ORDER BY Entry_ID
                LOOP
                    _jobParam := format('%s<Param Section="%s" Name="%s" Value="%s" />',
                                        _jobParam, _sectionName, _keyName, _value);
                END LOOP;

                If _mode <> 'add' Then
                    _mode := 'previewAdd';
                End If;

                If _toolName::citext = 'MaxQuant' Then
                    _scriptName := 'MaxQuant_DataPkg';
                End If;

                If _toolName::citext = 'MSFragger' Then
                    _scriptName := 'MSFragger_DataPkg';
                End If;

                If _toolName::citext = 'DiaNN' Then
                    _scriptName := 'DiaNN_DataPkg';
                End If;

                CALL sw.add_update_local_job_in_broker (
                                    _job => _pipelineJob,                           -- Output
                                    _scriptName => _scriptName,
                                    _datasetName => 'Aggregation',
                                    _priority => _priority,
                                    _jobParam => _jobParam,
                                    _comment => _comment,
                                    _ownerUsername => _ownerUsername,
                                    _dataPackageID => _dataPackageID,
                                    _resultsDirectoryName => _resultsDirectoryName, -- Output
                                    _mode => _mode,
                                    _message => _message,                           -- Output
                                    _returnCode => _returnCode,                     -- Output
                                    _callingUser => _callingUser,                   -- Output
                                    _debugMode => false,
                                    _logdebugmessages => false);

                If _returnCode <> '' Then
                    _msgForLog := format('Error code %s from sw.pipeline_add_update_local_job: %s', _returnCode, Coalesce(_message, '??'));
                    CALL post_log_entry ('Error', _msgForLog, 'Add_Analysis_Job_Group');
                End If;

                If _pipelineJob > 0 Then
                    -- Insert details for the job into t_analysis_job
                    CALL public.backfill_pipeline_jobs (
                                _infoOnly => false,
                                _jobsToProcess => 0,
                                _startJob => _pipelineJob,
                                _message => _msgForLog,         -- Output
                                _returnCode => _returnCode);    -- Output

                    If _returnCode = '' Then
                        -- Associate the new job with this job request
                        -- Also update settings file, parameter file, protein collection, etc.

                        UPDATE t_analysis_job
                        SET request_id = _requestID,
                            settings_file_name = _settingsFileName,
                            param_file_name = _paramFileName,
                            organism_id = _organismID,
                            protein_collection_list = _protCollNameList,
                            protein_options_list = _protCollOptionsList,
                            organism_db_name = _organismDBName
                        WHERE job = _pipelineJob;
                    Else
                        _msgForLog := format('Error code %s calling Backfill_Pipeline_Jobs: %s', _returnCode, Coalesce(_msgForLog, '??'));
                        CALL post_log_entry ('Error', _msgForLog, 'Add_Analysis_Job_Group');
                    End If;
                End If;

            End If;

            If _mode = 'add' Then
                ---------------------------------------------------
                -- Mark request as used
                ---------------------------------------------------

                _requestStateID := 2;

                UPDATE t_analysis_job_request
                SET request_state_id = _requestStateID
                WHERE request_id = _requestID;

                If char_length(_callingUser) > 0 Then
                    -- _callingUser is defined; call public.alter_event_log_entry_user or public.alter_event_log_entry_user_multi_id
                    -- to alter the entered_by field in t_event_log
                    --
                    CALL public.alter_event_log_entry_user ('public', 12, _requestID, _requestStateID, _callingUser, _message => _alterEnteredByMessage);
                End If;

                _message := format('Created aggregation job %s for ', _pipelineJob);

            ElsIf _returnCode = '' Then
                _message := 'Would create an aggregation job for ';

            End If;

            If _returnCode = '' Then
                _message := format('%s %s %s', _message, public.check_plural(_jobCountToBeCreated, 'dataset', 'datasets');
            End If;

            DROP TABLE Tmp_DatasetInfo;

            If _createdSettingsFileValuesTable Then
                DROP TABLE Tmp_SettingsFile_Values_DataPkgJob;
            End If;

            RETURN;
        End If;

        If _mode = 'add' Then

            If _jobCountToBeCreated = 0 And _datasetCountToRemove > 0 Then
                RAISE EXCEPTION 'No jobs were made for request % because there were existing jobs for all datasets in the list', _requestID;
            End If;

            ---------------------------------------------------
            -- Create a new batch if multiple jobs being created
            ---------------------------------------------------

            SELECT COUNT(*)
            INTO _numDatasets
            FROM Tmp_DatasetInfo;
            --
            If _numDatasets = 0 Then
                RAISE EXCEPTION 'No datasets in list to create jobs for request %', _requestID;
            End If;
            --
            If _numDatasets > 1 Then

                -- Create a new batch
                INSERT INTO t_analysis_job_batches (batch_description)
                VALUES ('Auto')
                RETURNING batch_id
                INTO _batchID;

            End If;

            ---------------------------------------------------
            -- Deal with request
            ---------------------------------------------------

            If _requestID = 0 Then
                _requestID := 1; -- for the default request
            Else
                -- Make sure _requestID is in state 1=new or state 5=new (Review Required)

                SELECT request_state_id
                INTO _requestStateID
                FROM t_analysis_job_request
                WHERE request_id = _requestID;

                _requestStateID := Coalesce(_requestStateID, 0);

                If _requestStateID In (1, 5) Then
                    -- Mark request as used
                    --
                    _requestStateID := 2;

                    UPDATE t_analysis_job_request
                    SET request_state_id = _requestStateID
                    WHERE request_id = _requestID;

                    If char_length(_callingUser) > 0 Then
                        -- _callingUser is defined; call public.alter_event_log_entry_user or public.alter_event_log_entry_user_multi_id
                        -- to alter the entered_by field in t_event_log
                        --
                        CALL public.alter_event_log_entry_user ('public', 12, _requestID, _requestStateID, _callingUser, _message => _alterEnteredByMessage);
                    End If;
                Else
                    -- Request ID is non-zero and request is not in state 1 or state 5
                    RAISE EXCEPTION 'Request is not in state New; cannot create jobs for request %', _requestID;
                End If;
            End If;

            ---------------------------------------------------
            -- Get new job number for every dataset
            -- in temporary table
            ---------------------------------------------------

            CREATE TEMP TABLE Tmp_NewJobIDs (ID int);

            _createdNewJobIDsTable := true;

            INSERT INTO Tmp_NewJobIDs (ID)
            SELECT Job
            FROM public.get_new_job_id_block(_numDatasets, 'Created in t_analysis_job');

            -- Use the job number information in Tmp_NewJobIDs to update Tmp_DatasetInfo

            -- If we know the first job number in Tmp_NewJobIDs, we can use
            -- the Row_Number() function to update Tmp_DatasetInfo

            _jobIDStart := 0;
            _jobIDEnd := 0;

            SELECT MIN(ID), MAX(ID)
            INTO _jobIDStart, _jobIDEnd
            FROM Tmp_NewJobIDs;

            -- Make sure _jobIDStart and _jobIDEnd define a contiguous block of jobs
            If _jobIDEnd - _jobIDStart + 1 <> _numDatasets Then
                RAISE EXCEPTION 'get_new_job_id_block did not return a contiguous block of jobs; requested % jobs but job range is % to %', _numDatasets, _jobIDStart, _jobIDEnd;
            End If;

            -- The JobQ subquery uses Row_Number() and _jobIDStart to define the new job numbers for each entry in Tmp_DatasetInfo
            UPDATE Tmp_DatasetInfo
            SET Job = JobQ.ID
            FROM ( SELECT Dataset_ID,
                          Row_Number() OVER ( ORDER BY Dataset_ID ) + _jobIDStart - 1 AS ID
                   FROM Tmp_DatasetInfo
                 ) JobQ
            WHERE Tmp_DatasetInfo.Dataset_ID = JobQ.Dataset_ID;

            ---------------------------------------------------
            -- Insert a new job in analysis job table for
            -- every dataset in temporary table
            ---------------------------------------------------

            INSERT INTO t_analysis_job (
                job,
                priority,
                created,
                analysis_tool_id,
                param_file_name,
                settings_file_name,
                organism_db_name,
                protein_collection_list,
                protein_options_list,
                organism_id,
                dataset_id,
                comment,
                special_processing,
                owner,
                batch_id,
                job_state_id,
                request_id,
                propagation_mode,
                dataset_unreviewed
            ) SELECT
                job,
                _priority,
                CURRENT_TIMESTAMP,
                _analysisToolID,
                _paramFileName,
                _settingsFileName,
                _organismDBName,
                _protCollNameList,
                _protCollOptionsList,
                _organismID,
                Tmp_DatasetInfo.dataset_id,
                REPLACE(_comment, '#DatasetNum#', Tmp_DatasetInfo.dataset_id::text),
                _specialProcessing,
                _ownerUsername,
                _batchID,
                _jobStateID,
                _requestID,
                _propMode,
                Coalesce(dataset_unreviewed, 1)
            FROM Tmp_DatasetInfo;
            --
            GET DIAGNOSTICS _jobCountToBeCreated = ROW_COUNT;

            If _batchID = 0 And _jobCountToBeCreated = 1 Then
                -- Added a single job; cache the jobID value
                _jobID := _jobIDStart;
            End If;
            /*
            ---------------------------------------------------
            -- Deprecated in May 2015: create associations with processor group for new
            -- jobs, if group ID is given
            ---------------------------------------------------

            If _gid <> 0 Then
                -- if single job was created, get its identity directly
                --
                If _batchID = 0 And _jobCountToBeCreated = 1 Then
                    INSERT INTO t_analysis_job_processor_group_associations (job, group_id)
                    VALUES (_jobID, _gid);
                End If;
                --
                -- if multiple jobs were created, get job identities
                -- from all jobs using new batch ID
                --
                If _batchID <> 0 And _jobCountToBeCreated >= 1 Then
                    INSERT INTO t_analysis_job_processor_group_associations (job, group_id)
                    SELECT job, _gid
                    FROM t_analysis_job
                    WHERE batch_id = _batchID;
                End If;
            End If;
            */

            If _requestID > 1 Then
                -------------------------------------------------
                -- Update the job_count field for this job request
                -------------------------------------------------

                UPDATE t_analysis_job_request target
                SET job_count = StatQ.JobCount
                FROM ( SELECT AJR.request_id,
                              SUM(CASE WHEN AJ.job IS NULL
                                       THEN 0
                                       ELSE 1
                                  END) AS JobCount
                       FROM t_analysis_job_request AJR
                           INNER JOIN t_users U
                               ON AJR.user_id = U.user_id
                           INNER JOIN t_analysis_job_request_state AJRS
                               ON AJR.request_state_id = AJRS.request_state_id
                           INNER JOIN t_organisms Org
                               ON AJR.organism_id = Org.organism_id
                           LEFT OUTER JOIN t_analysis_job AJ
                               ON AJR.request_id = AJ.request_id
                       WHERE AJR.request_id = _requestID
                       GROUP BY AJR.request_id
                       ) StatQ
                WHERE target.request_id = StatQ.request_id;

                CALL public.update_cached_job_request_existing_jobs (
                            _processingMode => 0,
                            _requestID => _requestID,
                            _jobSearchHours => 0,
                            _infoOnly => false,
                            _message => _message,           -- Output
                            _returnCode => _returnCode);    -- Output

            End If;

            If char_length(_callingUser) > 0 Then
                -- _callingUser is defined; call public.alter_event_log_entry_user or public.alter_event_log_entry_user_multi_id
                -- to alter the entered_by field in t_event_log
                --
                If _batchID = 0 Then
                    CALL public.alter_event_log_entry_user ('public', 5, _jobID, _jobStateID, _callingUser, _message => _alterEnteredByMessage);
                Else
                    -- Populate a temporary table with the list of Job IDs just created
                    CREATE TEMP TABLE Tmp_ID_Update_List (
                        TargetID int NOT NULL
                    );

                    CREATE UNIQUE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

                    INSERT INTO Tmp_ID_Update_List (TargetID)
                    SELECT DISTINCT job
                    FROM t_analysis_job
                    WHERE batch_id = _batchID

                    CALL public.alter_event_log_entry_user_multi_id ('public', 5, _jobStateID, _callingUser, _entryTimeWindowSeconds => 45, _message => _alterEnteredByMessage);

                    DROP TABLE Tmp_ID_Update_List;
                End If;
            End If;

        End If;

        ---------------------------------------------------
        -- Build message
        ---------------------------------------------------

        If _jobCountToBeCreated = 1 Then
            If _mode = 'add' Then
                _message := 'There was 1 job created.';
            Else
                _message := 'There would be 1 job created.';
            End If;
        Else
            If _mode = 'add' Then
                _message := 'There were ';
            Else
                _message := 'There would be ';
            End If;

            _message := format('%s %s %s created.',
                                _message,  _jobCountToBeCreated, public.check_plural(_jobCountToBeCreated, 'job', 'jobs');
        End If;

        If _datasetCountToRemove > 0 Then
            If _mode = 'add' Then
                _removedDatasets := format('Jobs were not made for %s', _removedDatasets);
            Else
                _removedDatasets := format('Jobs would not be made for %s', _removedDatasets);
            End If;

            _message := format('%s %s', _message, _removedDatasets);
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_ID_Update_List;
        DROP TABLE IF EXISTS Tmp_MatchingJobDatasets;
    END;

    DROP TABLE IF EXISTS Tmp_DatasetInfo;

    If _createdSettingsFileValuesTable Then
        DROP TABLE IF EXISTS Tmp_SettingsFile_Values_DataPkgJob;
    End If;

    If _createdNewJobIDsTable Then
        DROP TABLE IF EXISTS Tmp_NewJobIDs;
    End If;
END
$$;

COMMENT ON PROCEDURE public.add_analysis_job_group IS 'AddAnalysisJobGroup';
