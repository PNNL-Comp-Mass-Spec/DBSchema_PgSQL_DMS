--
CREATE OR REPLACE PROCEDURE public.add_update_analysis_job_request
(
    _datasets text,
    _requestName text,
    _toolName text,
    _paramFileName text,
    _settingsFileName text,
    _protCollNameList text,
    _protCollOptionsList text,
    _organismName text,
    _organismDBName text = 'na',
    _requesterUsername text,
    _comment text = null,
    _specialProcessing text = null,
    _dataPackageID int = 0,
    _state text,
    INOUT _requestID int,
    _mode text = 'add',
    _autoRemoveNotReleasedDatasets int = 0,     -- Leave this as an integer since used by the website
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new analysis job request to request queue
**
**  Arguments:
**    _datasets                         Comma separated list of datasets
**    _requestName                      Job request name
**    _toolName                         Tool name
**    _paramFileName                    Parameter file name
**    _settingsFileName                 Settings file name
**    _protCollNameList                 Comma-separated list of protein collection names
**    _protCollOptionsList              Protein collection options
**    _organismName                     Organism name
**    _organismDBName                   Legacy fasta file; typically 'na'
**    _requesterUsername                Requester username
**    _comment                          Job request comment
**    _specialProcessing                Special processing parameters; typically ''
**    _dataPackageID                    Data package ID
**    _state                            State, typically 'new', 'used', or 'inactive' (see T_Analysis_Job_Request_State)
**    _requestID                        Input/output: analysis job request ID
**    _mode                             Mode: 'add', 'update', 'append', or 'PreviewAdd'
**    _autoRemoveNotReleasedDatasets    When true, remove datasets that are not released
**    _message                          Output message
**    _returnCode                       Return code
**    _callingUser                      Calling user username
**
**  Auth:   grk
**  Date:   10/9/2003
**          02/11/2006 grk - Added validation for tool compatibility
**          03/28/2006 grk - Added protein collection fields
**          04/04/2006 grk - Increased sized of param file name
**          04/04/2006 grk - Modified to use Validate_Analysis_Job_Parameters
**          04/10/2006 grk - Widened size of list argument to 6000 characters
**          04/11/2006 grk - Modified logic to allow changing name of existing request
**          08/31/2006 grk - Restored apparently missing prior modification http://prismtrac.pnl.gov/trac/ticket/217
**          10/16/2006 jds - Added support for work package number
**          10/16/2006 mem - Updated to force _state to 'new' if _mode = 'add'
**          11/13/2006 mem - Now calling Validate_Protein_Collection_List_For_Datasets to validate _protCollNameList
**          11/30/2006 mem - Added column Dataset_Type to Tmp_DatasetInfo (Ticket:335)
**          12/20/2006 mem - Added column dataset_rating_id to Tmp_DatasetInfo (Ticket:339)
**          01/26/2007 mem - Switched to organism ID instead of organism name (Ticket:368)
**          05/22/2007 mem - Updated to prevent addition of duplicate datasets to  (Ticket:481)
**          10/11/2007 grk - Expand protein collection list size to 4000 characters (http://prismtrac.pnl.gov/trac/ticket/545)
**          01/17/2008 grk - Modified error codes to help debugging DMS2.  Also had to add explicit NULL column attribute to Tmp_DatasetInfo
**          02/22/2008 mem - Updated to convert _comment to '' if null (Ticket:648, http://prismtrac.pnl.gov/trac/ticket/648)
**          09/12/2008 mem - Now passing _paramFileName and _settingsFileName ByRef to Validate_Analysis_Job_Parameters (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**          09/24/2008 grk - Increased size of comment argument (and column in database)(Ticket:692, http://prismtrac.pnl.gov/trac/ticket/692)
**          12/02/2008 grk - Disallow editing unless in 'New' state
**          09/19/2009 grk - Added field to request admin review (Ticket #747, http://prismtrac.pnl.gov/trac/ticket/747)
**          09/19/2009 grk - Allowed updates from any state
**          09/22/2009 grk - Changed state 'review_required' to 'New (Review Required)'
**          09/22/2009 mem - Now setting state to 'New (Review Required)' if _state = 'new' and _adminReviewReqd='Yes'
**          10/02/2009 mem - Revert to only allowing updates if the state is 'New' or 'New (Review Required)'
**          02/12/2010 mem - Now assuring that rating is not -5 (note: when converting a job request to jobs, you can manually add datasets with a rating of -5; procedure Add_Analysis_Job_Group will allow them to be included)
**          04/21/2010 grk - Use try-catch for error handling
**          05/05/2010 mem - Now passing _requestorPRN to Validate_Analysis_Job_Parameters as input/output
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          03/21/2011 mem - Expanded _datasets to varchar(max) and _requestName to varchar(128)
**                         - Now using SCOPE_IDENTITY() to determine the ID of the newly added request
**          03/29/2011 grk - Added _specialProcessing argument (http://redmine.pnl.gov/issues/304)
**          05/16/2011 mem - Now auto-removing duplicate datasets and auto-formatting _datasets
**          04/02/2012 mem - Now auto-removing datasets named 'Dataset' or 'Dataset_Name' in _datasets
**          05/15/2012 mem - Added _organismDBName
**          07/16/2012 mem - Now auto-changing _protCollOptionsList to 'seq_direction=forward,filetype=fasta' if the tool is MSGFPlus (MSGFDB) and the options start with 'seq_direction=decoy'
**          07/24/2012 mem - Now allowing _protCollOptionsList to be 'seq_direction=decoy,filetype=fasta' for MSGFPlus searches where the parameter file name contains '_NoDecoy'
**          09/25/2012 mem - Expanded _organismDBName and _organismName to varchar(128)
**          11/05/2012 mem - Now auto-changing the settings file from FinniganDefSettings.xml to FinniganDefSettings_DeconMSN.xml if the request contains HMS% datasets
**          11/05/2012 mem - Now disallowing mixing low res MS datasets with high res HMS dataset
**          11/12/2012 mem - Moved dataset validation logic to validate_analysis_job_request_datasets
**          11/14/2012 mem - Now assuring that _toolName is properly capitalized
**          11/20/2012 mem - Removed parameter _workPackage
**          12/13/2013 mem - Updated _mode to support 'PreviewAdd'
**          01/11/2013 mem - Renamed MSGF-DB search tool to MSGFPlus
**          03/05/2013 mem - Added parameter _autoRemoveNotReleasedDatasets, which is passed to Validate_Analysis_Job_Parameters
**          03/26/2013 mem - Added parameter _callingUser
**          04/09/2013 mem - Now automatically updating the settings file to the MSConvert equivalent if processing QExactive data
**          05/22/2013 mem - Now preventing an update of analysis job requests only if they have existing analysis jobs (previously would examine request_state_id in T_Analysis_Job_Request)
**          06/10/2013 mem - Now filtering on Analysis_Tool when checking whether an HMS_AutoSupersede file exists for the given settings file
**          03/28/2014 mem - Auto-changing _protCollOptionsList to 'seq_direction=decoy,filetype=fasta' if the tool is MODa and the options start with 'seq_direction=forward'
**          03/30/2015 mem - Now passing _toolName to Auto_Update_Settings_File_To_Centroid
**                         - Now using T_Dataset_Info.ProfileScanCount_MSn to look for datasets with profile-mode MS/MS spectra
**          04/08/2015 mem - Now passing _autoUpdateSettingsFileToCentroided = false to Validate_Analysis_Job_Parameters
**          10/09/2015 mem - Now allowing the request name and comment to be updated even if a request has associated jobs
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/11/2016 mem - Disabled forcing use of MSConvert for QExactive datasets
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/23/2016 mem - Include the request name when calling post_log_entry from within the catch block
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2017 mem - Set _allowNewDatasets to true when calling Validate_Analysis_Job_Parameters
**          05/23/2018 mem - Do not allow _requestorPRN to be the autouser (login H09090911)
**          06/12/2018 mem - Send _maxLength to append_to_text
**          04/17/2019 mem - Auto-change _protCollOptionsList to 'seq_direction=forward,filetype=fasta' when running TopPIC
**          04/23/2019 mem - Auto-change _protCollOptionsList to 'seq_direction=decoy,filetype=fasta' when running MSFragger
**          07/30/2019 mem - Store dataset info in table T_Analysis_Job_Request_Datasets instead of the Datasets column in T_Analysis_Job_Request
**                         - Call Update_Cached_Job_Request_Existing_Jobs after creating / updating an analysis job request
**          05/28/2020 mem - Auto-update the settings file if the samples used TMTpro
**          03/10/2021 mem - Add _dataPackageID and remove _adminReviewReqd
**          05/28/2021 mem - Add _mode 'append', which can be be used to add additional datasets to an existing analysis job request, regardless of state
**                         - When using append mode, optionally Set _state to 'new' to also reset the state
**          10/15/2021 mem - Require that _dataPackageID be defined when using a match between runs parameter file for MaxQuant and MSFragger
**          03/10/2022 mem - Replace spaces and tabs in the dataset list with commas
**          05/23/2022 mem - Rename requester argument
**          06/30/2022 mem - Rename parameter file argument
**          03/22/2023 mem - Also auto-remove datasets named 'Dataset Name' and 'Dataset_Name' from Tmp_DatasetInfo
**          03/27/2023 mem - Synchronize protein collection options validation with add_analysis_job_group
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetCount int := 0;
    _autoSupersedeName text := '';
    _msgToAppend text;
    _logErrors boolean := false;
    _datasetMin text := NULL;
    _datasetMax text := NULL;
    _tmtProDatasets int := 0;
    _datasetCount int := 0;
    _msg text;
    _hit int;
    _curState int;
    _currentName text;
    _currentComment text;
    _collectionCountAdded int;
    _userID int;
    _analysisToolID int;
    _organismID int;
    _warning text;
    _priority int;
    _profileModeMSnDatasets int := 0;
    _stateID int := -1;
    _newRequestNum int;
    _logMessage text;
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

        _requestName       := Trim(Coalesce(_requestName, ''));
        _comment           := Trim(Coalesce(_comment, ''));
        _requesterUsername := Trim(Coalesce(_requesterUsername, ''));
        _dataPackageID     := Coalesce(_dataPackageID, 0);
        _datasets          := Trim(Coalesce(_datasets, ''));
        _mode              := Trim(Lower(Coalesce(_mode, '')));

        If _requestName = '' Then
            RAISE EXCEPTION 'Cannot add: request name must be specified';
        End If;

        If _requesterUsername = 'H09090911' Or _requesterUsername = 'Autouser' Then
            RAISE EXCEPTION 'Cannot add: the "Requested by" username cannot be the Autouser';
        End If;

        If _dataPackageID < 0 Then
            _dataPackageID := 0;
        End If;

        -- Replace spaces and tabs with commas
        _datasets := Replace(Replace(_datasets, ' ', ','), chr(9), ',');

        ---------------------------------------------------
        -- Resolve mode against presence or absence
        -- of request in database, and its current state
        ---------------------------------------------------

        -- Cannot create an entry with a duplicate name
        --
        If _mode::citext In ('add', 'PreviewAdd') Then
            If Exists (SELECT request_id FROM t_analysis_job_request WHERE request_name = _requestName::citext) Then
                RAISE EXCEPTION 'Cannot add: request with same name already in database';
            End If;
        End If;

        -- Cannot update a non-existent entry
        -- If the entry already exists and has jobs associated with it, only allow for updating the comment field
        --
        If _mode = 'update' Then

            SELECT request_id,
                   request_state_id
            INTO _hit, _curState
            FROM t_analysis_job_request
            WHERE request_id = _requestID;

            If Not FOUND Then
                RAISE EXCEPTION 'Cannot update: entry is not in database';
            End If;

            If Exists (Select job From t_analysis_job Where request_id = _requestID) Then
                -- The request has jobs associated with it

                SELECT request_name,
                       comment
                INTO _currentName, _currentComment
                FROM t_analysis_job_request
                WHERE request_id = _requestID;

                If _currentName <> _requestName Or _currentComment <> _comment Then
                    UPDATE t_analysis_job_request
                    SET request_name = _requestName,
                        comment = _comment
                    WHERE request_id = _requestID;

                    If _currentName <> _requestName And _currentComment <> _comment Then
                        _message := 'Updated the request name and comment';
                    Else
                        If _currentName <> _requestName Then
                            _message := 'Updated the request name';
                        End If;

                        If _currentComment <> _comment Then
                            _message := 'Updated the request comment';
                        End If;
                    End If;

                    RETURN;
                Else
                    RAISE EXCEPTION 'Entry has analysis jobs associated with it; only the comment and name can be updated';
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- We either need datasets or a data package
        ---------------------------------------------------

        If _dataPackageID > 0 And _datasets <> '' Then
            RAISE EXCEPTION 'Dataset list must be empty when a Data Package ID is defined';
        End If;

        If _dataPackageID = 0 And _datasets = '' Then
            RAISE EXCEPTION 'Dataset list is empty';
        End If;

        ---------------------------------------------------
        -- Create temporary table to hold list of datasets
        -- This procedure populates column Dataset_Name
        -- Procedure validate_analysis_job_request_datasets (called by validate_analysis_job_parameters) will populate the remaining columns
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetInfo (
            Dataset_Name citext,
            Dataset_ID int NULL,
            Instrument_Class text NULL,
            Dataset_State_ID int NULL,
            Archive_State_ID int NULL,
            Dataset_Type text NULL,
            Dataset_Rating_ID smallint NULL
        );

        If _dataPackageID > 0 Then
            ---------------------------------------------------
            -- Populate table using the datasets currently associated with the data package
            -- Remove any duplicates that may be present
            ---------------------------------------------------

            INSERT INTO Tmp_DatasetInfo ( Dataset_Name )
            SELECT DISTINCT Dataset
            FROM dpkg.V_Data_Package_Dataset_Export
            WHERE Data_Package_ID = _dataPackageID
            --
            GET DIAGNOSTICS _datasetCount = ROW_COUNT;

            If _datasetCount = 0 Then
                RAISE EXCEPTION 'Data package does not have any datasets associated with it';
            End If;
        Else
            ---------------------------------------------------
            -- Populate table from dataset list
            -- Remove any duplicates that may be present
            ---------------------------------------------------

            INSERT INTO Tmp_DatasetInfo (Dataset_Name)
            SELECT DISTINCT Value
            FROM public.parse_delimited_list(_datasets)
            --
            GET DIAGNOSTICS _datasetCount = ROW_COUNT;

            If _returnCode <> '' Then
                RAISE EXCEPTION 'Error populating temporary table';
            End If;

            ---------------------------------------------------
            --Auto-delete dataset column names from Tmp_DatasetInfo
            ---------------------------------------------------

            DELETE FROM Tmp_DatasetInfo
            WHERE Dataset_Name::citext IN ('Dataset', 'Dataset Name', 'Dataset_Name', 'Dataset_Num')
        End If;

        ---------------------------------------------------
        -- Find the first and last dataset in Tmp_DatasetInfo
        ---------------------------------------------------

        SELECT COUNT(*)
        INTO _datasetCount
        FROM Tmp_DatasetInfo

        If _datasetCount = 1 Then
            SELECT MIN(Dataset_Name)
            INTO _datasetMin
            FROM Tmp_DatasetInfo;
        Else
            SELECT MIN(Dataset_Name),
                   MAX(Dataset_Name)
            INTO _datasetMin, _datasetMax
            FROM Tmp_DatasetInfo;
        End If;

        ---------------------------------------------------
        -- Create and populate the temporary table used by validate_protein_collection_list_for_dataset_table
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetList (
            Dataset_Name text Not NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_DatasetList ON Tmp_DatasetList ( Dataset_Name );

        INSERT INTO Tmp_DatasetList( Dataset_Name )
        SELECT DISTINCT Dataset_Name
        FROM Tmp_DatasetInfo;

        ---------------------------------------------------
        -- Validate _protCollNameList
        --
        -- Note that validate_protein_collection_list_for_dataset_table will populate _message with an explanatory note
        -- if _protCollNameList is updated
        ---------------------------------------------------

        _protCollNameList := Trim(Coalesce(_protCollNameList, ''));

        If char_length(_protCollNameList) > 0 And public.validate_na_parameter(_protCollNameList, 1) <> 'na' Then
            CALL public.validate_protein_collection_list_for_dataset_table (
                                _protCollNameList => _protCollNameList,             -- Output
                                _collectionCountAdded => _collectionCountAdded,     -- Output
                                _showMessages => _showMessages,
                                _message => _message,                               -- Output
                                _returncode => _returnCode,                         -- Output
                                _showDebug => false);

            If _returnCode <> '' Then
                DROP TABLE Tmp_DatasetInfo;
                DROP TABLE Tmp_DatasetList;
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Validate job parameters
        -- Note that validate_analysis_job_parameters calls validate_analysis_job_request_datasets
        -- and that validate_analysis_job_request_datasets populates Dataset_ID, etc. in Tmp_DatasetInfo
        ---------------------------------------------------

        _priority := 2;

        CALL public.validate_analysis_job_parameters (
                                _toolName => _toolName,
                                _paramFileName => _paramFileName,               -- Output
                                _settingsFileName => _settingsFileName,         -- Output
                                _organismDBName => _organismDBName,             -- Output
                                _organismName => _organismName,
                                _protCollNameList => _protCollNameList,         -- Output
                                _protCollOptionsList => _protCollOptionsList,   -- Output
                                _ownerUsername => _requesterUsername,           -- Output
                                _mode => '',                                    -- Blank validation mode to suppress dataset state checking
                                _userID => _userID,                             -- Output
                                _analysisToolID => _analysisToolID,             -- Output
                                _organismID => _organismID,                     -- Output
                                _job => 0,
                                _autoRemoveNotReleasedDatasets => CASE WHEN Coalesce(_autoRemoveNotReleasedDatasets, 0) = 0 THEN false ELSE true END,
                                _autoUpdateSettingsFileToCentroided => false,
                                _allowNewDatasets => true
                                _warning => _warning,                           -- Output
                                _priority => _priority,                         -- Output
                                _showDebugMessages => false,
                                _message => _msg,                               -- Output
                                _returnCode => _returnCode,                     -- Output
                                );
        --
        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Assure that _toolName is properly capitalized
        ---------------------------------------------------

        SELECT analysis_tool
        INTO _toolName
        FROM t_analysis_tool
        WHERE analysis_tool = _toolName

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

        /*
         * Disabled in March 2016 because not always required
         *
        ---------------------------------------------------
        -- Auto-update the settings file if one or more HMS datasets are present
        -- but the user chose a settings file that is not appropriate for HMS datasets
        ---------------------------------------------------

        If Exists (SELECT Dataset_Type FROM Tmp_DatasetInfo WHERE Dataset_Type LIKE 'hms%' OR Dataset_Type LIKE 'ims-hms%') Then
            -- Possibly auto-update the settings file

            SELECT hms_auto_supersede
            INTO _autoSupersedeName
            FROM t_settings_files
            WHERE 'file_name' = _settingsFileName AND
                   analysis_tool = _toolName

            If Coalesce(_autoSupersedeName, '') <> '' Then
                _settingsFileName := _autoSupersedeName;

                _msgToAppend := format('Note: Auto-updated the settings file to %s because one or more HMS datasets are included in this job request', _autoSupersedeName);
                _message := public.append_to_text(_message, _msgToAppend, _delimiter => ';', _maxlength => 512);
            End If;
        End If;
        */

        -- Declare _qExactiveDSCount int = 0

        /*
         * Disabled in March 2016 because not always required
         *
        -- Count the number of QExactive datasets
        --
        SELECT COUNT(*)
        INTO _qExactiveDSCount
        FROM Tmp_DatasetInfo
                INNER JOIN t_dataset DS ON Tmp_DatasetInfo.dataset = DS.dataset
                INNER JOIN t_instrument_name InstName ON DS.instrument_id = InstName.instrument_id
                INNER JOIN t_instrument_group InstGroup ON InstName.instrument_group = InstGroup.instrument_group
        WHERE InstGroup.instrument_group = 'QExactive'
        */

        -- Count the number of datasets with profile mode MS/MS
        --
        SELECT COUNT(Distinct DS.dataset_id)
        INTO _profileModeMSnDatasets
        FROM Tmp_DatasetInfo
                INNER JOIN t_dataset DS ON Tmp_DatasetInfo.dataset = DS.dataset
                INNER JOIN t_dataset_info DI ON DS.dataset_id = DI.dataset_id
        WHERE DI.profile_scan_count_msn > 0

        If _profileModeMSnDatasets > 0 Then
            -- Auto-update the settings file since we have one or more Q Exactive datasets or one or more datasets with profile-mode MS/MS spectra
            _autoSupersedeName := public.auto_update_settings_file_to_centroid(_settingsFileName, _toolName);

            If Coalesce(_autoSupersedeName, '') <> _settingsFileName Then
                _settingsFileName := _autoSupersedeName;
                _msgToAppend := format('Note: Auto-updated the settings file to %s', _autoSupersedeName);

                If _profileModeMSnDatasets > 0 Then
                    _msgToAppend := format('%s because one or more datasets in this job request has profile-mode MSn spectra', _msgToAppend);
                Else
                    _msgToAppend := format('%s because one or more QExactive datasets are included in this job request', _msgToAppend);
                End If;

                _message := public.append_to_text(_message, _msgToAppend, _delimiter => ';', _maxlength => 512);
            End If;
        End If;

        ---------------------------------------------------
        -- Auto-change the settings file if TMTpro samples
        ---------------------------------------------------

        If (_toolName Like 'MSGFPlus%' And _settingsFileName Like '%TMT%') Then
            SELECT COUNT(Distinct DS.dataset_id)
            INTO _tmtProDatasets
            FROM Tmp_DatasetInfo
                INNER JOIN t_dataset DS ON Tmp_DatasetInfo.dataset = DS.dataset
                INNER JOIN t_experiments E ON DS.exp_id = E.exp_id
            WHERE E.labelling = 'TMT16' OR DS.dataset LIKE '%TMTpro%'

            If _tmtProDatasets > _datasetCount / 2.0 Then
                -- At least half of the datasets are 16-plex TMT; auto-update the settings file name, if necessary
                If _settingsFileName = 'IonTrapDefSettings_MzML_StatCysAlk_6plexTMT.xml' Then
                    _settingsFileName := 'IonTrapDefSettings_MzML_StatCysAlk_16plexTMT.xml';
                End If;

                If _settingsFileName = 'IonTrapDefSettings_MzML_6plexTMT.xml' Then
                    _settingsFileName := 'IonTrapDefSettings_MzML_16plexTMT.xml';
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- If adding/updating a match-between-runs job, require that a data package is defined
        ---------------------------------------------------

        If _toolName Like 'MSFragger%' And _dataPackageID = 0 And (_settingsFileName Like '%MatchBetweenRun%' Or _settingsFileName Like '%MBR%') Then
            RAISE EXCEPTION 'Use a data package to define datasets when performing a match-between-runs search with MSFragger';
        End If;

        If _toolName Like 'MaxQuant%'And _dataPackageID = 0 And (_paramFileName Like '%MatchBetweenRun%' Or _paramFileName Like '%MBR%') Then
            RAISE EXCEPTION 'Use a data package to define datasets when performing a match-between-runs search with MaxQuant';
        End If;

        ---------------------------------------------------
        -- If mode is add, force _state to 'new'
        ---------------------------------------------------

        If _mode::citext In ('add', 'PreviewAdd') Then
            -- Lookup the name for state 'New'
            SELECT request_state
            INTO _state
            FROM t_analysis_job_request_state
            WHERE request_state_id = 1;
        End If;

        ---------------------------------------------------
        -- Resolve state name to ID
        ---------------------------------------------------

        SELECT request_state_id
        INTO _stateID
        FROM t_analysis_job_request_state
        WHERE request_state = _state

        If _stateID = -1 Then
            RAISE EXCEPTION 'Could not resolve state name to ID';
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_analysis_job_request
            (
                request_name,
                created,
                analysis_tool,
                param_file_name,
                settings_file_name,
                organism_db_name,
                organism_id,
                protein_collection_list,
                protein_options_list,
                comment,
                special_processing,
                request_state_id,
                user_id,
                dataset_min,
                dataset_max,
                data_pkg_id
            )
            VALUES
            (
                _requestName,
                CURRENT_TIMESTAMP,
                _toolName,
                _paramFileName,
                _settingsFileName,
                _organismDBName,
                _organismID,
                _protCollNameList,
                _protCollOptionsList,
                _comment,
                _specialProcessing,
                _stateID,
                _userID,
                _datasetMin,
                _datasetMax,
                Case When _dataPackageId > 0 Then _dataPackageId Else Null End
            )
            RETURNING request_id
            INTO _newRequestNum;

            INSERT INTO t_analysis_job_request_datasets( request_id,
                                                         dataset_id )
            SELECT _newRequestNum, Tmp_DatasetInfo.dataset_id
            FROM Tmp_DatasetInfo;

            -- Return ID of the newly created request
            --
            _requestID := _newRequestNum;

            If char_length(_callingUser) > 0 Then
                -- _callingUser is defined; call public.alter_event_log_entry_user or public.alter_event_log_entry_user_multi_id
                -- to alter the entered_by field in t_event_log
                --
                CALL public.alter_event_log_entry_user ('public', 12, _requestID, _stateID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            CALL public.update_cached_job_request_existing_jobs (_processingMode => 0, _requestID => _requestID, _infoOnly => false);

        End If; -- add mode

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode::citext = 'PreviewAdd' Then
            _message := format('Would create request "%s" with parameter file "%s" and settings file "%s"',
                               _requestName, _paramFileName, _settingsFileName;
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode::citext In ('update', 'append') Then
            -- Update the request

            UPDATE t_analysis_job_request
            SET request_name = _requestName,
                analysis_tool = _toolName,
                param_file_name = _paramFileName,
                settings_file_name = _settingsFileName,
                organism_db_name = _organismDBName,
                organism_id = _organismID,
                protein_collection_list = _protCollNameList,
                protein_options_list = _protCollOptionsList,
                comment = _comment,
                special_processing = _specialProcessing,
                request_state_id = _stateID,
                user_id = _userID,
                dataset_min = _datasetMin,
                dataset_max = _datasetMax,
                data_pkg_id = CASE WHEN _dataPackageId > 0 THEN _dataPackageId ELSE Null END
            WHERE request_id = _requestID;

            MERGE INTO t_analysis_job_request_datasets AS t
            USING ( SELECT _requestID As Request_ID, Dataset_ID
                    FROM Tmp_DatasetInfo
                  ) AS s
            ON (t.dataset_id = s.dataset_id AND t.request_id = s.request_id)
            -- Note: all of the columns in table t_analysis_job_request_datasets are primary keys or identity columns; there are no updatable columns
            WHEN NOT MATCHED THEN
                INSERT (Request_ID, Dataset_ID)
                VALUES (s.Request_ID, s.Dataset_ID);

            DELETE FROM t_analysis_job_request_datasets target
            WHERE target.Request_ID = _requestID AND
                  NOT EXISTS (SELECT DI.Dataset_ID FROM Tmp_DatasetInfo DI WHERE target.dataset_id = DI.dataset_id);

            If char_length(_callingUser) > 0 Then
                -- _callingUser is defined; call public.alter_event_log_entry_user or public.alter_event_log_entry_user_multi_id
                -- to alter the entered_by field in t_event_log
                --
                CALL public.alter_event_log_entry_user ('public', 12, _requestID, _stateID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            CALL public.update_cached_job_request_existing_jobs (_processingMode => 0, _requestID => _requestID, _infoOnly => false);

        End If; -- update mode

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Request %s', _exceptionMessage, _requestName);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_DatasetInfo;
    DROP TABLE IF EXISTS Tmp_DatasetList;
END
$$;

COMMENT ON PROCEDURE public.add_update_analysis_job_request IS 'AddUpdateAnalysisJobRequest';
