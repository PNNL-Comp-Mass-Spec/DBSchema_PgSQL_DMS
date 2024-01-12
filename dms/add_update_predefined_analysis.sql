--
-- Name: add_update_predefined_analysis(integer, text, text, integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, integer, integer, text, text, text, integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_predefined_analysis(IN _level integer, IN _sequence text, IN _nextlevel text, IN _triggerbeforedisposition integer, IN _propagationmode text, IN _instrumentclasscriteria text, IN _instrumentnamecriteria text, IN _instrumentexclcriteria text, IN _campaignnamecriteria text, IN _campaignexclcriteria text, IN _experimentnamecriteria text, IN _experimentexclcriteria text, IN _experimentcommentcriteria text, IN _organismnamecriteria text, IN _datasetnamecriteria text, IN _datasetexclcriteria text, IN _datasettypecriteria text, IN _scantypecriteria text, IN _scantypeexclcriteria text, IN _labellinginclcriteria text, IN _labellingexclcriteria text, IN _separationtypecriteria text, IN _analysistoolname text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _organismdbname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _priority integer, IN _enabled integer, IN _description text, IN _specialprocessing text, IN _creator text, INOUT _id integer, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or update an existing predefined analysis job definition
**
**  Arguments:
**    _level                        Level; datasets are compared to predefines sequentially, by level
**    _sequence                     Sequence; for each level, predefines are processed sequentially, by sequence
**    _nextLevel                    Next level to jump to if a dataset matches a predefine
**    _triggerBeforeDisposition     Trigger before disposition: 1 means to trigger before datasets are dispositioned; 0 means to trigger after disposition
**    _propagationMode              Propagation mode: 'Export' or 'No export'
**    _instrumentClassCriteria      Instrument class criteria
**    _instrumentNameCriteria       Instrument name criteria
**    _instrumentExclCriteria       Instrument excl criteria
**    _campaignNameCriteria         Campaign name criteria
**    _campaignExclCriteria         Campaign exclusion criteria
**    _experimentNameCriteria       Experiment name criteria
**    _experimentExclCriteria       Experiment exclusion criteria
**    _experimentCommentCriteria    Experiment comment criteria
**    _organismNameCriteria         Organism name criteria
**    _datasetNameCriteria          Dataset name criteria
**    _datasetExclCriteria          Dataset exclusion criteria
**    _datasetTypeCriteria          Dataset type criteria
**    _scanTypeCriteria             Scan type criteria
**    _scanTypeExclCriteria         Scan type exclusion criteria
**    _labellingInclCriteria        Labelling inclusion criteria
**    _labellingExclCriteria        Labelling exclusion criteria
**    _separationTypeCriteria       Separation type criteria
**    _analysisToolName             Analysis tool name
**    _paramFileName                Param file name
**    _settingsFileNam              Settings file nam
**    _organismName                 Organism name
**    _organismDBName               Organism database name (legacy FASTA file)
**    _protCollNameList             Comma-separated list of protein collection names
**    _protCollOptionsList          Protein collection options
**    _priority                     Priority to assign to jobs created from the predefine
**    _enabled                      Enabled: 1 if enabled, 0 if disabled
**    _description                  Description
**    _specialProcessing            Special processing parameters; typically ''
**    _creator                      Username of the DMS user who created the predefine
**    _id                           Input/output: Predefine ID in t_predefined_analysis
**    _mode                         Mode: 'add' or 'update'
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   grk
**  Date:   06/21/2005 grk - Superseded AddUpdateDefaultAnalysis
**          03/28/2006 grk - Added protein collection fields
**          01/26/2007 mem - Switched to organism ID instead of organism name (Ticket #368)
**          07/30/2007 mem - Now validating dataset type and instrument class for the matching instruments against the specified analysis tool (Ticket #502)
**          08/06/2008 mem - Added new filter criteria: SeparationType, CampaignExclusion, ExperimentExclusion, and DatasetExclusion (Ticket #684)
**          09/04/2009 mem - Added DatasetType parameter
**          09/16/2009 mem - Now checking dataset type against the Instrument_Allowed_Dataset_Type table (Ticket #748)
**          10/05/2009 mem - Now validating the parameter file name
**          12/18/2009 mem - Switched to use GetInstrumentDatasetTypeList() to get the allowed dataset types for the dataset and GetAnalysisToolAllowedDSTypeList() to get the allowed dataset types for the analysis tool
**          05/06/2010 mem - Now calling auto_resolve_name_to_username to validate _creator
**          08/26/2010 mem - Now calling Validate_Protein_Collection_Params to validate the protein collection info
**          08/28/2010 mem - Now using T_Instrument_Group_Allowed_DS_Type to determine allowed dataset types for matching instruments
**                         - Added try-catch for error handling
**          11/12/2010 mem - Now using T_Analysis_Tool_Allowed_Instrument_Class to lookup the allowed instrument class names for a given analysis tool
**          02/09/2011 mem - Added parameter _triggerBeforeDisposition
**          02/16/2011 mem - Added parameter _propagationMode
**          05/02/2012 mem - Added parameter _specialProcessing
**          09/25/2012 mem - Expanded _organismNameCriteria and _organismName to varchar(128)
**          04/18/2013 mem - Expanded _description to varchar(512)
**          11/02/2015 mem - Population of Tmp_MatchingInstruments now considers the DatasetType criterion
**          02/23/2016 mem - Add set XACT_ABORT on
**          10/27/2016 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**                         - Explicitly update Last_Affected
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/21/2017 mem - Add _instrumentExclCriteria
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/10/2018 mem - Validate the settings file name
**          12/08/2020 mem - Lookup username from T_Users using the validated user ID
**          06/30/2022 mem - Rename parameter file argument
**          12/06/2023 mem - Add support for scan type criteria
**                         - Ported to PostgreSQL
**          01/03/2024 mem - Update warning messages
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          01/11/2024 mem - Show a custom message when _mode is 'update' but _id is null
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _allowedDatasetTypes text;
    _allowedDSTypesForTool text;
    _allowedInstClassesForTool text;

    _matchCount int;
    _dropTempTable boolean := false;
    _instrument record;
    _analysisToolID int;
    _msg text := '';
    _propMode int;
    _seqVal int;
    _nextLevelVal int;
    _organismID int;
    _ownerUsername text;
    _userID int;
    _newUsername text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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

        _analysisToolName := Trim(Coalesce(_analysisToolName, ''));
        _paramFileName    := Trim(Coalesce(_paramFileName   , ''));
        _settingsFileName := Trim(Coalesce(_settingsFileName, ''));
        _organismName     := Trim(Coalesce(_organismName    , ''));
        _organismDBName   := Trim(Coalesce(_organismDBName  , ''));

        If _analysisToolName = '' Then
            _returnCode := 'U5201';
            RAISE EXCEPTION 'Analysis tool name must be specified';
        End If;

        If _paramFileName = '' Then
            _returnCode := 'U5202';
            RAISE EXCEPTION 'Parameter file name must be specified';
        End If;

        If _settingsFileName = '' Then
            _returnCode := 'U5203';
            RAISE EXCEPTION 'Settings file name must be specified';
        End If;

        If _organismName = '' Then
            _returnCode := 'U5204';
            RAISE EXCEPTION 'Organism name must be specified; use "(default)" to auto-assign at job creation';
        End If;

        If _organismDBName = '' Then
            _returnCode := 'U5205';
            RAISE EXCEPTION 'Organism DB name must be specified';
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Update any null filter criteria
        ---------------------------------------------------

        _triggerBeforeDisposition  := Coalesce(_triggerBeforeDisposition, 0);
        _priority                  := Coalesce(_priority, 3);
        _enabled                   := Coalesce(_enabled, 1);

        _instrumentClassCriteria   := Trim(Coalesce(_instrumentClassCriteria  , ''));
        _instrumentNameCriteria    := Trim(Coalesce(_instrumentNameCriteria   , ''));
        _instrumentExclCriteria    := Trim(Coalesce(_instrumentExclCriteria   , ''));
        _campaignNameCriteria      := Trim(Coalesce(_campaignNameCriteria     , ''));
        _campaignExclCriteria      := Trim(Coalesce(_campaignExclCriteria     , ''));
        _experimentNameCriteria    := Trim(Coalesce(_experimentNameCriteria   , ''));
        _experimentExclCriteria    := Trim(Coalesce(_experimentExclCriteria   , ''));
        _experimentCommentCriteria := Trim(Coalesce(_experimentCommentCriteria, ''));
        _datasetNameCriteria       := Trim(Coalesce(_datasetNameCriteria      , ''));
        _datasetExclCriteria       := Trim(Coalesce(_datasetExclCriteria      , ''));
        _datasetTypeCriteria       := Trim(Coalesce(_datasetTypeCriteria      , ''));
        _scanTypeCriteria          := Trim(Coalesce(_scanTypeCriteria         , ''));
        _scanTypeExclCriteria      := Trim(Coalesce(_scanTypeExclCriteria     , ''));
        _labellingInclCriteria     := Trim(Coalesce(_labellingInclCriteria    , ''));
        _labellingExclCriteria     := Trim(Coalesce(_labellingExclCriteria    , ''));
        _separationTypeCriteria    := Trim(Coalesce(_separationTypeCriteria   , ''));
        _organismName              := Trim(Coalesce(_organismName             , ''));
        _protCollNameList          := Trim(Coalesce(_protCollNameList         , ''));
        _protCollOptionsList       := Trim(Coalesce(_protCollOptionsList      , ''));
        _description               := Trim(Coalesce(_description              , ''));
        _specialProcessing         := Trim(Coalesce(_specialProcessing        , ''));

        ---------------------------------------------------
        -- Resolve propagation mode
        ---------------------------------------------------

        _propMode := CASE Lower(Coalesce(_propagationMode, ''))
                        WHEN 'export' THEN 0
                        WHEN 'no export' THEN 1
                        ELSE 0
                     END;

        ---------------------------------------------------
        -- Validate _level, _sequence, and _nextLevel
        ---------------------------------------------------

        If _level Is Null Then
            _msg := 'Level cannot be null';
            RAISE EXCEPTION '%', _msg;
        End If;

        If Trim(Coalesce(_sequence, '')) <> '' Then
            _seqVal := try_cast(_sequence, null::int);

            If _seqVal Is Null Then
                _msg := format('Sequence should be an integer (or an empty string), not "%s"', _sequence);
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        If Trim(Coalesce(_nextLevel, '')) <> '' Then
            _nextLevelVal := try_cast(_nextLevel, null::int);

            If _nextLevelVal Is Null Then
                _msg := format('NextLevel should be an integer (or an empty string), not "%s"', _nextLevel);
                RAISE EXCEPTION '%', _msg;
            End If;

            If _nextLevelVal <= _level Then
                _msg := format('Next level (%s) must be greater than current level (%s)', _nextLevel, _level);
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        --------------------------------------------------
        -- Validate the analysis tool name
        --------------------------------------------------

        SELECT analysis_tool_id
        INTO _analysisToolID
        FROM t_analysis_tool
        WHERE analysis_tool = _analysisToolName::citext;

        If Not FOUND Then
            _msg := format('Analysis tool "%s" not found in t_analysis_tool', _analysisToolName);
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- If _instrumentClassCriteria or _instrumentNameCriteria or _instrumentExclCriteria are defined,
        -- determine the associated Dataset Types and make sure they are valid for _analysisToolName
        ---------------------------------------------------

        If _instrumentClassCriteria <> '' Or _instrumentNameCriteria <> '' Or _instrumentExclCriteria <> '' Then

            If Not Exists ( SELECT ADT.Dataset_Type
                            FROM t_analysis_tool_allowed_dataset_type ADT
                                 INNER JOIN t_analysis_tool Tool
                                   ON ADT.analysis_tool_id = Tool.analysis_tool_id
                            WHERE Tool.analysis_tool = _analysisToolName::citext
                          ) Then
                _msg := format('Analysis tool "%s" does not have any allowed dataset types; unable to continue', _analysisToolName);
                RAISE EXCEPTION '%', _msg;
            End If;

            If Not Exists ( SELECT AIC.Instrument_Class
                            FROM t_analysis_tool_allowed_instrument_class AIC
                                 INNER JOIN t_analysis_tool Tool
                                   ON AIC.analysis_tool_id = Tool.analysis_tool_id
                            WHERE Tool.analysis_tool = _analysisToolName::citext
                          ) Then

                _msg := format('Analysis tool "%s" does not have any allowed instrument classes; unable to continue', _analysisToolName);
                RAISE EXCEPTION '%', _msg;

            End If;

            ---------------------------------------------------
            -- Populate a temporary table with allowed dataset types
            -- associated with the matching instruments
            ---------------------------------------------------

            CREATE TEMP TABLE Tmp_MatchingInstruments (
                UniqueID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                InstrumentName text,
                InstrumentClass text,
                InstrumentID int
            );

            _dropTempTable := true;

            INSERT INTO Tmp_MatchingInstruments (
                InstrumentName,
                InstrumentClass,
                InstrumentID
            )
            SELECT DISTINCT InstName.instrument,
                            InstClass.instrument_class,
                            InstName.instrument_id
            FROM t_instrument_name InstName
                 INNER JOIN t_instrument_class InstClass
                   ON InstName.instrument_class = InstClass.instrument_class
                 INNER JOIN t_instrument_group_allowed_ds_type InstGroupDSType
                   ON InstName.instrument_group = InstGroupDSType.instrument_group AND
                      (InstGroupDSType.dataset_type LIKE _datasetTypeCriteria OR _datasetTypeCriteria = '')
            WHERE (InstClass.instrument_class LIKE _instrumentClassCriteria OR _instrumentClassCriteria = '') AND
                  (InstName.instrument LIKE _instrumentNameCriteria OR _instrumentNameCriteria = '') AND
                  (NOT (InstName.instrument LIKE _instrumentExclCriteria) OR _instrumentExclCriteria = '');
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _matchCount = 0 Then
                _msg := 'Did not match any instruments using the instrument name, instrument class, and dataset type criteria; update not allowed';
                RAISE EXCEPTION '%', _msg;
            End If;

            ---------------------------------------------------
            -- Step through Tmp_MatchingInstruments and make sure
            -- each entry has at least one Dataset Type that is present in t_analysis_tool_allowed_dataset_type
            -- for this analysis tool
            --
            -- Also validate each instrument class with t_analysis_tool_allowed_instrument_class
            ---------------------------------------------------

            FOR _instrument IN
                SELECT UniqueID,
                       InstrumentName,
                       InstrumentID,
                       InstrumentClass
                FROM Tmp_MatchingInstruments
                ORDER BY UniqueID
            LOOP
                If Not Exists ( SELECT instrument_id
                                FROM t_instrument_name InstName
                                     INNER JOIN t_instrument_group_allowed_ds_type IGADT
                                       ON InstName.instrument_group = IGADT.instrument_group
                                     INNER JOIN ( SELECT ADT.dataset_type
                                                  FROM t_analysis_tool_allowed_dataset_type ADT
                                                       INNER JOIN t_analysis_tool Tool
                                                         ON ADT.analysis_tool_id = Tool.analysis_tool_id
                                                  WHERE (Tool.analysis_tool = _analysisToolName)
                                                ) ToolQ
                                       ON IGADT.dataset_type = ToolQ.dataset_type
                                WHERE (InstName.instrument = _instrument.InstrumentName)
                              ) Then

                    -- Example criteria that will result in this message: Instrument Criteria=Agilent_TOF%, Tool=AgilentSequest

                    _allowedDatasetTypes := public.get_instrument_dataset_type_list(_instrument.InstrumentID);

                    SELECT AllowedDatasetTypes
                    INTO _allowedDSTypesForTool
                    FROM public.get_analysis_tool_allowed_dataset_type_list(_analysisToolID);

                    _msg := format('Criteria matched instrument "%s" with allowed dataset types of "%s"; however, analysis tool %s allows these dataset types: "%s"',
                                   _instrument.InstrumentName, _allowedDatasetTypes, _analysisToolName, _allowedDSTypesForTool);

                    RAISE EXCEPTION '%', _msg;
                End If;

                If Not Exists ( SELECT AIC.Instrument_Class
                                FROM t_analysis_tool_allowed_instrument_class AIC
                                    INNER JOIN t_analysis_tool Tool
                                    ON AIC.analysis_tool_id = Tool.analysis_tool_id
                                WHERE Tool.analysis_tool = _analysisToolName AND
                                    AIC.instrument_class = _instrument.InstrumentClass
                              ) Then

                    -- Example criteria that will result in this message: Instrument Class=BRUKERFTMS, Tool=XTandem
                    -- 2nd example: Instrument Criteria=Agilent_TOF%, Tool=Decon2LS

                    SELECT AllowedInstrumentClasses
                    INTO _allowedInstClassesForTool
                    FROM public.get_analysis_tool_allowed_instrument_class_list(_analysisToolID);

                    _msg := format('Criteria matched instrument "%s" which is Instrument Class "%s"; however, analysis tool %s allows these instrument classes: "%s"',
                                   _instrument.InstrumentName, _instrument.InstrumentClass, _analysisToolName, _allowedInstClassesForTool);

                    RAISE EXCEPTION '%', _msg;
                END If;

            END LOOP;

        End If;

        ---------------------------------------------------
        -- Resolve organism ID
        ---------------------------------------------------

        _organismID := public.get_organism_id(_organismName);

        If _organismID = 0 Then
            _msg := format('Invalid organism name: "%s" does not exist', _organismName);
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Validate the parameter file name
        ---------------------------------------------------

        If _paramFileName::citext <> 'na' Then
            If Not Exists (SELECT param_file_id FROM t_param_files WHERE param_file_name = _paramFileName::citext) Then
                _msg := format('Invalid parameter file: "%s" does not exist', _paramFileName);
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Validate the settings file name
        ---------------------------------------------------

        If _settingsFileName::citext <> 'na' Then
            If Not Exists (SELECT settings_file_id FROM t_settings_files WHERE file_name = _settingsFileName::citext) Then
                _msg := format('Invalid settings file: "%s" does not exist', _settingsFileName);
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Check protein parameters
        ---------------------------------------------------

        _ownerUsername := '';

        CALL public.validate_protein_collection_params (
                        _analysisToolName,
                        _organismDBName      => _organismDBName,        -- Output
                        _organismName        => _organismName,
                        _protCollNameList    => _protCollNameList,      -- Output
                        _protCollOptionsList => _protCollOptionsList,   -- Output
                        _ownerUsername       => _ownerUsername,
                        _message             => _message,               -- Output
                        _returnCode          => _returnCode,            -- Output
                        _debugMode           => false);

        If _returnCode <> '' Then
            _msg := _message;
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- _creator should be a username
        -- Auto-capitalize it or auto-resolve it from a name to a username
        ---------------------------------------------------

        _userID := public.get_user_id(_creator);

        If _userID > 0 Then
            -- Function get_user_id() recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _creator contains simply the username

            SELECT username
            INTO _creator
            FROM t_users
            WHERE user_id = _userID;
        Else
            ---------------------------------------------------
            -- _creator did not resolve to a user_id
            --
            -- In case a name was entered (instead of a username),
            -- try to auto-resolve using the name column in t_users
            ---------------------------------------------------

            CALL public.auto_resolve_name_to_username (
                            _creator,
                            _matchCount       => _matchCount,   -- Output
                            _matchingUsername => _newUsername,  -- Output
                            _matchingUserID   => _userID);      -- Output

            If _matchCount = 1 Then
                -- Single match was found; update _creator
                _creator := _newUsername;
            End If;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            If _id Is Null Then
                _message := 'Cannot update: predefine ID cannot be null';
                RAISE WARNING '%', _message;

                _returnCode := 'U5202';
                RETURN;
            End If;

            -- Cannot update a non-existent entry

            If Not Exists (SELECT predefine_id FROM t_predefined_analysis WHERE predefine_id = _id) Then
                _msg := format('Cannot update: predefine ID %s does not exist', _id);
                RAISE EXCEPTION '%', _msg;
            End If;

        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_predefined_analysis (
                predefine_level,
                predefine_sequence,
                next_level,
                trigger_before_disposition,
                propagation_mode,
                instrument_class_criteria,
                instrument_name_criteria,
                instrument_excl_criteria,
                campaign_name_criteria,
                campaign_excl_criteria,
                experiment_name_criteria,
                experiment_excl_criteria,
                exp_comment_criteria,
                organism_name_criteria,
                dataset_name_criteria,
                dataset_excl_criteria,
                dataset_type_criteria,
                scan_type_criteria,
                scan_type_excl_criteria,
                labelling_incl_criteria,
                labelling_excl_criteria,
                separation_type_criteria,
                analysis_tool_name,
                param_file_name,
                settings_file_name,
                organism_id,
                organism_db_name,
                protein_collection_list,
                protein_options_list,
                priority,
                enabled,
                description,
                special_processing,
                creator,
                last_affected
            ) VALUES (
                _level,
                _seqVal,
                _nextLevelVal,
                _triggerBeforeDisposition,
                _propMode,
                _instrumentClassCriteria,
                _instrumentNameCriteria,
                _instrumentExclCriteria,
                _campaignNameCriteria,
                _campaignExclCriteria,
                _experimentNameCriteria,
                _experimentExclCriteria,
                _experimentCommentCriteria,
                _organismNameCriteria,
                _datasetNameCriteria,
                _datasetExclCriteria,
                _datasetTypeCriteria,
                _scanTypeCriteria,
                _scanTypeExclCriteria,
                _labellingInclCriteria,
                _labellingExclCriteria,
                _separationTypeCriteria,
                _analysisToolName,
                _paramFileName,
                _settingsFileName,
                _organismID,
                _organismDBName,
                _protCollNameList,
                _protCollOptionsList,
                _priority,
                _enabled,
                _description,
                _specialProcessing,
                _creator,
                CURRENT_TIMESTAMP
            )
            RETURNING predefine_id
            INTO _id;

        End If; -- add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_predefined_analysis
            SET predefine_level            = _level,
                predefine_sequence         = _seqVal,
                next_level                 = _nextLevelVal,
                trigger_before_disposition = _triggerBeforeDisposition,
                propagation_mode           = _propMode,
                instrument_class_criteria  = _instrumentClassCriteria,
                instrument_name_criteria   = _instrumentNameCriteria,
                instrument_excl_criteria   = _instrumentExclCriteria,
                campaign_name_criteria     = _campaignNameCriteria,
                campaign_excl_criteria     = _campaignExclCriteria,
                experiment_name_criteria   = _experimentNameCriteria,
                experiment_excl_criteria   = _experimentExclCriteria,
                exp_comment_criteria       = _experimentCommentCriteria,
                organism_name_criteria     = _organismNameCriteria,
                dataset_name_criteria      = _datasetNameCriteria,
                dataset_excl_criteria      = _datasetExclCriteria,
                dataset_type_criteria      = _datasetTypeCriteria,
                scan_type_criteria         = _scanTypeCriteria,
                scan_type_excl_criteria    = _scanTypeExclCriteria,
                labelling_incl_criteria    = _labellingInclCriteria,
                labelling_excl_criteria    = _labellingExclCriteria,
                separation_type_criteria   = _separationTypeCriteria,
                analysis_tool_name         = _analysisToolName,
                param_file_name            = _paramFileName,
                settings_file_name         = _settingsFileName,
                organism_id                = _organismID,
                organism_db_name           = _organismDBName,
                protein_collection_list    = _protCollNameList,
                protein_options_list       = _protCollOptionsList,
                priority                   = _priority,
                enabled                    = _enabled,
                description                = _description,
                special_processing         = _specialProcessing,
                creator                    = _creator,
                last_affected              = CURRENT_TIMESTAMP
            WHERE predefine_id = _id;

        End If;

        If _dropTempTable Then
            DROP TABLE Tmp_MatchingInstruments;
        End If;

        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _id Is Null Then
            _logMessage := _exceptionMessage;
        Else
            _logMessage := format('%s; Predefine ID %s', _exceptionMessage, _id);
        End If;

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    If _dropTempTable Then
        DROP TABLE IF EXISTS Tmp_MatchingInstruments;
    End If;
END
$$;


ALTER PROCEDURE public.add_update_predefined_analysis(IN _level integer, IN _sequence text, IN _nextlevel text, IN _triggerbeforedisposition integer, IN _propagationmode text, IN _instrumentclasscriteria text, IN _instrumentnamecriteria text, IN _instrumentexclcriteria text, IN _campaignnamecriteria text, IN _campaignexclcriteria text, IN _experimentnamecriteria text, IN _experimentexclcriteria text, IN _experimentcommentcriteria text, IN _organismnamecriteria text, IN _datasetnamecriteria text, IN _datasetexclcriteria text, IN _datasettypecriteria text, IN _scantypecriteria text, IN _scantypeexclcriteria text, IN _labellinginclcriteria text, IN _labellingexclcriteria text, IN _separationtypecriteria text, IN _analysistoolname text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _organismdbname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _priority integer, IN _enabled integer, IN _description text, IN _specialprocessing text, IN _creator text, INOUT _id integer, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_predefined_analysis(IN _level integer, IN _sequence text, IN _nextlevel text, IN _triggerbeforedisposition integer, IN _propagationmode text, IN _instrumentclasscriteria text, IN _instrumentnamecriteria text, IN _instrumentexclcriteria text, IN _campaignnamecriteria text, IN _campaignexclcriteria text, IN _experimentnamecriteria text, IN _experimentexclcriteria text, IN _experimentcommentcriteria text, IN _organismnamecriteria text, IN _datasetnamecriteria text, IN _datasetexclcriteria text, IN _datasettypecriteria text, IN _scantypecriteria text, IN _scantypeexclcriteria text, IN _labellinginclcriteria text, IN _labellingexclcriteria text, IN _separationtypecriteria text, IN _analysistoolname text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _organismdbname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _priority integer, IN _enabled integer, IN _description text, IN _specialprocessing text, IN _creator text, INOUT _id integer, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_predefined_analysis(IN _level integer, IN _sequence text, IN _nextlevel text, IN _triggerbeforedisposition integer, IN _propagationmode text, IN _instrumentclasscriteria text, IN _instrumentnamecriteria text, IN _instrumentexclcriteria text, IN _campaignnamecriteria text, IN _campaignexclcriteria text, IN _experimentnamecriteria text, IN _experimentexclcriteria text, IN _experimentcommentcriteria text, IN _organismnamecriteria text, IN _datasetnamecriteria text, IN _datasetexclcriteria text, IN _datasettypecriteria text, IN _scantypecriteria text, IN _scantypeexclcriteria text, IN _labellinginclcriteria text, IN _labellingexclcriteria text, IN _separationtypecriteria text, IN _analysistoolname text, IN _paramfilename text, IN _settingsfilename text, IN _organismname text, IN _organismdbname text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _priority integer, IN _enabled integer, IN _description text, IN _specialprocessing text, IN _creator text, INOUT _id integer, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdatePredefinedAnalysis';

