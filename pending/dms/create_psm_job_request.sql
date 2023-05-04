--
CREATE OR REPLACE PROCEDURE public.create_psm_job_request
(
    INOUT _requestID int,
    _requestName text,
    INOUT _datasets text,
    _toolName text,
    _jobTypeName text,
    _protCollNameList text,
    _protCollOptionsList text,
    _dynMetOxEnabled int,
    _statCysAlkEnabled int,
    _dynSTYPhosEnabled int,
    _comment text,
    _ownerUsername text,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Creates a new analysis job request using the appropriate
**      parameter file and settings file for the specified settings
**
**  Arguments:
**    _datasets   Input/output parameter; comma-separated list of datasets; will be alphabetized after removing duplicates
**
**  Auth:   mem
**  Date:   11/14/2012 mem - Initial version
**          11/21/2012 mem - No longer passing work package to AddUpdateAnalysisJobRequest
**                         - Now calling PostUsageLogEntry
**          12/13/2012 mem - Added parameter _previewMode, which indicates what should be passed to AddUpdateAnalysisJobRequest for _mode
**          01/11/2013 mem - Renamed MSGF-DB search tool to MSGFPlus
**          03/05/2013 mem - Now passing _autoRemoveNotReleasedDatasets to ValidateAnalysisJobRequestDatasets
**          04/09/2013 mem - Now automatically updating the settings file to the MSConvert equivalent if processing QExactive data
**          03/30/2015 mem - Now passing _toolName to AutoUpdateSettingsFileToCentroid
**                         - Now using T_Dataset_Info.ProfileScanCount_MSn to look for datasets with profile-mode MS/MS spectra
**          04/23/2015 mem - Now passing _toolName to ValidateAnalysisJobRequestDatasets
**          03/21/2016 mem - Add support for column Enabled
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Update grammar
**                         - Exclude logging some try/catch errors
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2017 mem - Set _allowNewDatasets to true when calling ValidateAnalysisJobRequestDatasets
**          03/19/2021 mem - Remove obsolete parameter from call to AddUpdateAnalysisJobRequest
**          06/06/2022 mem - Use new argument name when calling AddUpdateAnalysisJobRequest
**          06/30/2022 mem - Rename parameter file argument
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _result int;
    _settingsFile text;
    _paramFile text;
    _msg text;
    _datasetCount int := 0;
    _logErrors boolean := false;
    _qExactiveDSCount int := 0;
    _profileModeMSnDatasets int := 0;
    _organismName text := '';
    _mode text := 'add';
    _usageMessage text;

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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _requestID := 0;
        _toolName := Coalesce(_toolName, '');

        _requestName := Coalesce(_requestName, 'New ' || _toolName || ' request on ' || public.timestamp_text(current_timestamp));
        _datasets := Coalesce(_datasets, '');
        _jobTypeName := Coalesce(_jobTypeName, '');
        _protCollNameList := Coalesce(_protCollNameList, '');
        _protCollOptionsList := Coalesce(_protCollOptionsList, '');

        _dynMetOxEnabled := Coalesce(_dynMetOxEnabled, 0);
        _statCysAlkEnabled := Coalesce(_statCysAlkEnabled, 0);
        _dynSTYPhosEnabled := Coalesce(_dynSTYPhosEnabled, 0);

        _comment := Coalesce(_comment, '');
        _ownerUsername := Coalesce(_ownerUsername, session_user);
        _infoOnly := Coalesce(_infoOnly, false);
        _callingUser := Coalesce(_callingUser, '');

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Assure that key parameters are not empty
        ---------------------------------------------------
        --
        If Coalesce(_datasets, '') = '' Then
            RAISE EXCEPTION 'Dataset list is empty';
        End If;

        If Coalesce(_toolName, '') = '' Then
            RAISE EXCEPTION 'Tool name is empty';
        End If;

        If Coalesce(_jobTypeName, '') = '' Then
            RAISE EXCEPTION 'Job Type Name is empty';
        End If;

        If Coalesce(_protCollNameList, '') = '' Then
            RAISE EXCEPTION 'Protein collection list is empty';
        End If;

        ---------------------------------------------------
        -- Assure that _jobTypeName, _toolName, and _requestName are valid
        ---------------------------------------------------
        --
        If Not Exists (SELECT * FROM t_default_psm_job_types WHERE job_type_name = _jobTypeName) Then
            RAISE EXCEPTION 'Invalid job type name: %', _jobTypeName;
        End If;

        If Not Exists (SELECT * FROM t_default_psm_job_settings WHERE tool_name = _toolName AND enabled > 0) Then
            RAISE EXCEPTION 'Invalid analysis tool for creating a defaults-based PSM job: %', _toolName;
        End If;

        If Exists (SELECT * FROM t_analysis_job_request WHERE request_name = _requestName) Then
            RAISE EXCEPTION 'Cannot add; analysis job request named "%" already exists', _requestName;
        End If;

        If _toolName::citext LIKE '%_DTARefinery' And _jobTypeName = 'Low Res MS1' Then
            RAISE EXCEPTION 'DTARefinery cannot be used with datasets that have low resolution MS1 spectra';
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Create temporary table to hold list of datasets
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetInfo (
            Dataset_Name text,
            Dataset_ID int NULL,
            Instrument_class text NULL,
            Dataset_State_ID int NULL,
            Archive_State_ID int NULL,
            Dataset_Type text NULL,
            Dataset_rating int NULL
        )
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        CREATE INDEX IX_TD_DatasetID ON Tmp_DatasetInfo (Dataset_ID)

        ---------------------------------------------------
        -- Populate Tmp_DatasetInfo using the dataset list
        -- Remove any duplicates that may be present
        ---------------------------------------------------
        --
        INSERT INTO Tmp_DatasetInfo ( Dataset_Name )
        SELECT DISTINCT Item
        FROM public.parse_delimited_list ( _datasets )
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _datasetCount := _myRowCount;

        ---------------------------------------------------
        -- Validate the datasets in Tmp_DatasetInfo
        ---------------------------------------------------

        Call validate_analysis_job_request_datasets (
                    _message => _message,                   -- Output
                    _autoRemoveNotReleasedDatasets => true,
                    _toolName => _toolName,
                    _allowNewDatasets => true);

        If _returnCode <> '' Then
            _logErrors := false;
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Regenerate the dataset list, sorting by dataset name
        ---------------------------------------------------

        SELECT string_agg(Dataset_Name, ', ')
        INTO _datasets
        FROM Tmp_DatasetInfo
        ORDER BY Dataset_Name

        ---------------------------------------------------
        -- Determine the appropriate parameter file and settings file given _toolName and _jobTypeName
        ---------------------------------------------------

        -- First determine the settings file
        --
        SELECT settings_file_name
        INTO _settingsFile
        FROM t_default_psm_job_settings
        WHERE tool_name = _toolName AND
              job_type_name = _jobTypeName AND
              stat_cys_alk = _statCysAlkEnabled AND
              dyn_sty_phos = _dynSTYPhosEnabled AND
              enabled > 0;

        If Coalesce(_settingsFile, '') = '' Then
            _msg := 'Tool ' || _toolName || ' with job type ' || _jobTypeName || ' does not have a default settings file defined for ' ||;
                       'Stat Cys Alk ' || dbo.TinyintToEnabledDisabled(_statCysAlkEnabled) || ' and ' ||
                       'Dyn STY Phos ' || dbo.TinyintToEnabledDisabled(_dynSTYPhosEnabled)

            RAISE EXCEPTION '%', _msg;
        End If;

        -- Count the number of QExactive datasets
        --
        SELECT COUNT(*)
        INTO _qExactiveDSCount
        FROM Tmp_DatasetInfo
             INNER JOIN t_dataset DS ON Tmp_DatasetInfo.dataset = DS.dataset
             INNER JOIN t_instrument_name InstName ON DS.instrument_id = InstName.instrument_id
             INNER JOIN t_instrument_group InstGroup ON InstName.instrument_group = InstGroup.instrument_group
        WHERE (InstGroup.instrument_group = 'QExactive');

        -- Count the number of datasets with profile mode MS/MS
        --
        SELECT COUNT(Distinct DS.dataset_id)
        INTO _profileModeMSnDatasets
        FROM Tmp_DatasetInfo
           INNER JOIN t_dataset DS ON Tmp_DatasetInfo.dataset = DS.dataset
             INNER JOIN t_dataset_info DI ON DS.dataset_id = DI.dataset_id
        WHERE DI.profile_scan_count_msn > 0;

        If _qExactiveDSCount > 0 Or _profileModeMSnDatasets > 0 Then
            -- Auto-update the settings file since we have one or more Q Exactive datasets or one or more datasets with profile-mode MS/MS spectra
            _settingsFile := dbo.AutoUpdateSettingsFileToCentroid(_settingsFile, _toolName);
        End If;

        -- Next determine the parameter file
        --
        SELECT parameter_file_name
        INTO _paramFile
        FROM t_default_psm_job_parameters
        WHERE job_type_name = _jobTypeName AND
              tool_name = _toolName AND
              dyn_met_ox = _dynMetOxEnabled AND
              stat_cys_alk = _statCysAlkEnabled AND
              dyn_sty_phos = _dynSTYPhosEnabled AND
              enabled > 0;

        If Coalesce(_paramFile, '') = '' And _toolName::citext Like '%_DTARefinery' Then
            -- Remove '_DTARefinery' from the end of _toolName and re-query t_default_psm_job_parameters

            SELECT parameter_file_name
            INTO _paramFile
            FROM t_default_psm_job_parameters
            WHERE job_type_name = _jobTypeName AND
                tool_name = Replace(_toolName::citext, '_DTARefinery', '') AND
                dyn_met_ox = _dynMetOxEnabled AND
                stat_cys_alk = _statCysAlkEnabled AND
                dyn_sty_phos = _dynSTYPhosEnabled AND
                enabled > 0;

        End If;

        If Coalesce(_paramFile, '') = '' And _toolName::citext Like '%_MzML' Then
            -- Remove '_MzML' from the end of _toolName and re-query t_default_psm_job_parameters

            SELECT parameter_file_name
            INTO _paramFile
            FROM t_default_psm_job_parameters
            WHERE job_type_name = _jobTypeName AND
                tool_name = Replace(_toolName::citext, '_MzML', '') AND
                dyn_met_ox = _dynMetOxEnabled AND
                stat_cys_alk = _statCysAlkEnabled AND
                dyn_sty_phos = _dynSTYPhosEnabled AND
                enabled > 0;

        End If;

        If Coalesce(_paramFile, '') = '' Then
            _msg := 'Tool ' || _toolName || ' with job type ' || _jobTypeName || ' does not have a default parameter file defined for ' ||;
                        'Dyn Met Ox ' ||   dbo.TinyintToEnabledDisabled(_dynMetOxEnabled) || ', ' ||
                        'Stat Cys Alk ' || dbo.TinyintToEnabledDisabled(_statCysAlkEnabled) || ', and ' ||
                        'Dyn STY Phos ' || dbo.TinyintToEnabledDisabled(_dynSTYPhosEnabled)

            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Lookup the most common organism for the datasets in Tmp_DatasetInfo
        ---------------------------------------------------
        --

        SELECT t_organisms.organism
        INTO _organismName
        FROM Tmp_DatasetInfo
             INNER JOIN t_dataset DS
               ON Tmp_DatasetInfo.dataset_id = DS.dataset_id
             INNER JOIN t_experiments E
               ON DS.exp_id = E.exp_id
             INNER JOIN t_organisms
             ON E.organism_id = t_organisms.organism_id
        GROUP BY t_organisms.organism
        order BY COUNT(*) DESC
        LIMIT 1;

        ---------------------------------------------------
        -- Automatically switch from decoy to forward if using MSGFPlus
        -- AddUpdateAnalysisJobRequest also does this, but it displays a warning message to the user
        -- We don't want the warning message to appear when the user is using CreatePSMJobRequest; instead we silently update things
        ---------------------------------------------------
        --
        If _toolName::citext Like TO 'MSGFPlus%' And _protCollOptionsList::citext Like '%decoy%' And _paramFile::citext Not Like '%[_]NoDecoy%' Then
            _protCollOptionsList := 'seq_direction=forward,filetype=fasta';
        End If;

        If _infoOnly Then
            _mode := Lower('PreviewAdd');
        End If;

        ---------------------------------------------------
        -- Now create the analysis job request
        ---------------------------------------------------
        --
        Call add_update_analysis_job_request (
                _datasets => _datasets,
                _requestName => _requestName,
                _toolName => _toolName,
                _paramFileName => _paramFile,
                _settingsFileName => _settingsFile,
                _protCollNameList => _protCollNameList,
                _protCollOptionsList => _protCollOptionsList,
                _organismName => _organismName,
                _organismDBName => 'na',                    -- Legacy fasta file
                _requesterUsername => _ownerUsername,
                _comment => _comment,
                _specialProcessing => null,
                _state => 'New',
                _requestID => _requestID,       -- Output
                _mode => _mode,
                _message => _message,           -- Output
                _returnCode => _returnCode);    -- Output

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
    END;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If _requestID > 0 Then
        _usageMessage := 'Created job request ' || _requestID::text || ' for ' || _datasetCount::text || ' dataset';
        If _datasetCount <> 1 Then
            _usageMessage := _usageMessage || 's';
        End If;

        _usageMessage := _usageMessage || '; user ' || _callingUser;

        Call post_usage_log_entry ('CreatePSMJobRequest', _usageMessage, _minimumUpdateInterval => 2);
    End If;

    DROP TABLE IF EXISTS Tmp_DatasetInfo;
END
$$;

COMMENT ON PROCEDURE public.create_psm_job_request IS 'CreatePSMJobRequest';
