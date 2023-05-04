--
CREATE OR REPLACE PROCEDURE public.add_update_predefined_analysis
(
    _level int,
    _sequence text,
    _instrumentClassCriteria text,
    _campaignNameCriteria text,
    _experimentNameCriteria text,
    _instrumentNameCriteria text,
    _instrumentExclCriteria text,
    _organismNameCriteria text,
    _datasetNameCriteria text,
    _expCommentCriteria text,
    _labellingInclCriteria text,
    _labellingExclCriteria text,
    _analysisToolName text,
    _paramFileName text,
    _settingsFileName text,
    _organismName text,
    _organismDBName text,
    _protCollNameList text,
    _protCollOptionsList text,
    _priority int,
    _enabled int,
    _description text,
    _creator text,
    _nextLevel text,
    INOUT _id int,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _separationTypeCriteria text = '',
    _campaignExclCriteria text = '',
    _experimentExclCriteria text = '',
    _datasetExclCriteria text = '',
    _datasetTypeCriteria text = '',
    _triggerBeforeDisposition int = 0,
    _propagationMode text='Export',
    _specialProcessing text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a new default analysis to DB
**
**  Arguments:
**    _mode   'add' or 'update'
**
**  Auth:   grk
**  Date:   06/21/2005 grk - superseded AddUpdateDefaultAnalysis
**          03/28/2006 grk - added protein collection fields
**          01/26/2007 mem - Switched to organism ID instead of organism name (Ticket #368)
**          07/30/2007 mem - Now validating dataset type and instrument class for the matching instruments against the specified analysis tool (Ticket #502)
**          08/06/2008 mem - Added new filter criteria: SeparationType, CampaignExclusion, ExperimentExclusion, and DatasetExclusion (Ticket #684)
**          09/04/2009 mem - Added DatasetType parameter
**          09/16/2009 mem - Now checking dataset type against the Instrument_Allowed_Dataset_Type table (Ticket #748)
**          10/05/2009 mem - Now validating the parameter file name
**          12/18/2009 mem - Switched to use GetInstrumentDatasetTypeList() to get the allowed dataset types for the dataset and GetAnalysisToolAllowedDSTypeList() to get the allowed dataset types for the analysis tool
**          05/06/2010 mem - Now calling auto_resolve_name_to_username to validate _creator
**          08/26/2010 mem - Now calling ValidateProteinCollectionParams to validate the protein collection info
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
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          06/30/2022 mem - Rename parameter file argument
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _allowedDatasetTypes text;
    _allowedDSTypesForTool text;
    _allowedInstClassesForTool text;
    _uniqueID int;
    _continue boolean;
    _matchCount int;
    _instrumentName text;
    _instrumentID int;
    _instrumentClass text;
    _analysisToolID int;
    _msg text := '';
    _propMode int;
    _seqVal int;
    _nextLevelVal int;
    _organismID int;
    _ownerUsername text;
    _userID int;
    _newUsername text;
    _tmp int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';

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
        -- Validate input fields
        ---------------------------------------------------

        If char_length(Coalesce(_analysisToolName,'')) < 1 Then
            _returnCode := 'U5201';
            RAISE EXCEPTION 'Analysis tool name was blank';
        End If;

        If char_length(Coalesce(_paramFileName,'')) < 1 Then
            _returnCode := 'U5202';
            RAISE EXCEPTION 'Parameter file name was blank';
        End If;

        If char_length(Coalesce(_settingsFileName,'')) < 1 Then
            _returnCode := 'U5203';
            RAISE EXCEPTION 'Settings file name was blank';
        End If;

        If char_length(Coalesce(_organismName,'')) < 1 Then
            _returnCode := 'U5204';
            RAISE EXCEPTION 'Organism name was blank; use "(default)" to auto-assign at job creation';
        End If;

        If char_length(Coalesce(_organismDBName,'')) < 1 Then
            _returnCode := 'U5205';
            RAISE EXCEPTION 'Organism DB name was blank';
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Update any null filter criteria
        ---------------------------------------------------

        _instrumentClassCriteria := Trim(Coalesce(_instrumentClassCriteria, ''));
        _campaignNameCriteria := Trim(Coalesce(_campaignNameCriteria   , ''));
        _experimentNameCriteria := Trim(Coalesce(_experimentNameCriteria , ''));
        _instrumentNameCriteria := Trim(Coalesce(_instrumentNameCriteria , ''));
        _instrumentExclCriteria := Trim(Coalesce(_instrumentExclCriteria , ''));
        _organismNameCriteria := Trim(Coalesce(_organismNameCriteria   , ''));
        _datasetNameCriteria := Trim(Coalesce(_datasetNameCriteria    , ''));
        _expCommentCriteria := Trim(Coalesce(_expCommentCriteria     , ''));
        _labellingInclCriteria := Trim(Coalesce(_labellingInclCriteria  , ''));
        _labellingExclCriteria := Trim(Coalesce(_labellingExclCriteria  , ''));
        _separationTypeCriteria := Trim(Coalesce(_separationTypeCriteria , ''));
        _campaignExclCriteria := Trim(Coalesce(_campaignExclCriteria   , ''));
        _experimentExclCriteria := Trim(Coalesce(_experimentExclCriteria , ''));
        _datasetExclCriteria := Trim(Coalesce(_datasetExclCriteria    , ''));
        _datasetTypeCriteria := Trim(Coalesce(_datasetTypeCriteria    , ''));
        _specialProcessing := Trim(Coalesce(_specialProcessing      , ''));

        ---------------------------------------------------
        -- Resolve propagation mode
        ---------------------------------------------------
        _propMode := CASE Coalesce(_propagationMode, '');
                            WHEN 'Export' THEN 0
                            WHEN 'No Export' THEN 1
                            ELSE 0
                     END;

        ---------------------------------------------------
        -- Validate _sequence and _nextLevel
        ---------------------------------------------------

        If _sequence <> '' Then
        _seqVal := _sequence::int;
        End If;

        If _nextLevel <> '' Then
        _nextLevelVal := _nextLevel::int;
        If _nextLevelVal <= _level Then
                _msg := 'Next level must be greater than current level';
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        --------------------------------------------------
        -- Validate the analysis tool name
        --------------------------------------------------

        SELECT analysis_tool_id
        INTO _analysisToolID
        FROM t_analysis_tool
        WHERE (analysis_tool = _analysisToolName)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 Then
            _msg := 'Analysis tool "' || _analysisToolName || '" not found in t_analysis_tool';
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- If _instrumentClassCriteria or _instrumentNameCriteria or _instrumentExclCriteria are defined,
        -- determine the associated Dataset Types and make sure they are
        -- valid for _analysisToolName
        ---------------------------------------------------

        If char_length(_instrumentClassCriteria) > 0 Or char_length(_instrumentNameCriteria) > 0 Or char_length(_instrumentExclCriteria) > 0 Then
        -- <a>

            If Not Exists ( Then
                SELECT ADT.Dataset_Type;
            End If;
                FROM t_analysis_tool_allowed_dataset_type ADT
                     INNER JOIN t_analysis_tool Tool
                       ON ADT.analysis_tool_id = Tool.analysis_tool_id
                WHERE (Tool.analysis_tool = _analysisToolName)
                )
            Begin
                _msg := 'Analysis tool "' || _analysisToolName || '" does not have any allowed dataset types; unable to continue';
                RAISE EXCEPTION '%', _msg;
            End If;

            If Not Exists ( SELECT AIC.Instrument_Class
                            FROM t_analysis_tool_allowed_instrument_class AIC
                                 INNER JOIN t_analysis_tool Tool
                                   ON AIC.analysis_tool_id = Tool.analysis_tool_id
                            WHERE (Tool.analysis_tool = _analysisToolName)
                          ) Then

                _msg := 'Analysis tool "' || _analysisToolName || '" does not have any allowed instrument classes; unable to continue';
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
            )

            INSERT INTO Tmp_MatchingInstruments( InstrumentName,
                                                 InstrumentClass,
                                                 InstrumentID )
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
                  (NOT (InstName.instrument LIKE _instrumentExclCriteria) OR _instrumentExclCriteria = '')
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount = 0 Then
            -- <b1>
                _msg := 'Did not match any instruments using the instrument name and class criteria; update not allowed';
                RAISE EXCEPTION '%', _msg;
            End If; -- </b1>

            ---------------------------------------------------
            -- Step through Tmp_MatchingInstruments and make sure
            -- each entry has at least one Dataset Type that is present in t_analysis_tool_allowed_dataset_type
            -- for this analysis tool
            --
            -- Also validate each instrument class with t_analysis_tool_allowed_instrument_class
            ---------------------------------------------------

            _uniqueID := 0;
            _continue := true;

            WHILE _continue
            LOOP
                -- This While loop can probably be converted to a For loop; for example:
                --    FOR _itemName IN
                --        SELECT item_name
                --        FROM TmpSourceTable
                --        ORDER BY entry_id
                --    LOOP
                --        ...
                --    END LOOP

                SELECT UniqueID,
                       InstrumentName,
                       InstrumentID,
                       InstrumentClass
                INTO _uniqueID, _instrumentName, _instrumentID, _instrumentClass
                FROM Tmp_MatchingInstruments
                WHERE UniqueID > _uniqueID
                ORDER BY UniqueID
                LIMIT 1;
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                If _myRowCount = 0 Then
                    _continue := false;
                Else
                -- <c>

                    If Not Exists ( Then
                        SELECT *;
                    End If;
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
                        WHERE (InstName.instrument = _instrumentName)
                        )
                    Begin -- <d1>
                        -- Example criteria that will result in this message: Instrument Criteria=Agilent_TOF%, Tool=AgilentSequest

                        _allowedDatasetTypes := dbo.GetInstrumentDatasetTypeList(_instrumentID);

                        _allowedDSTypesForTool := '';
                        SELECT AllowedDatasetTypes
                        INTO _allowedDSTypesForTool
                        FROM dbo.GetAnalysisToolAllowedDSTypeList(_analysisToolID)

                        _msg := format('Criteria matched instrument "%s" with allowed dataset types of "%s"; however, analysis tool %s allows these dataset types: "%s"',
                                        _instrumentName, _allowedDatasetTypes, _analysisToolName, _allowedDSTypesForTool);

                        RAISE EXCEPTION '%', _msg;
                    End If;     -- </d1>

                    If Not Exists (
                        SELECT AIC.Instrument_Class;
                        FROM t_analysis_tool_allowed_instrument_class AIC
                            INNER JOIN t_analysis_tool Tool
                            ON AIC.analysis_tool_id = Tool.analysis_tool_id
                        WHERE Tool.analysis_tool = _analysisToolName AND
                            AIC.instrument_class = _instrumentClass
                        ) Then
                    Begin -- <d2>
                        -- Example criteria that will result in this message: Instrument Class=BRUKERFTMS, Tool=XTandem
                        -- 2nd example: Instrument Criteria=Agilent_TOF%, Tool=Decon2LS


                        SELECT AllowedInstrumentClasses
                        INTO _allowedInstClassesForTool
                        FROM dbo.GetAnalysisToolAllowedInstClassList (_analysisToolID)

                        _msg := format('Criteria matched instrument "%s" which is Instrument Class "%s"; however, analysis tool %s allows these instrument classes: "%s"'
                                        _instrumentName, _instrumentClass, _analysisToolName, _allowedInstClassesForTool);

                        RAISE EXCEPTION '%', _msg;
                    END LOOP;     -- </d2>

                END IF; -- </c>
            END LOOP; -- </b2>

        End If; -- </a>

        ---------------------------------------------------
        -- Resolve organism ID
        ---------------------------------------------------

        _organismID := get_organism_id(_organismName);

        If _organismID = 0 Then
            _msg := 'Could not find entry in database for organismName "' || _organismName || '"';
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Validate the parameter file name
        ---------------------------------------------------
        --
        If _paramFileName <> 'na' Then
            If Not Exists (SELECT * FROM t_param_files WHERE param_file_name = _paramFileName) Then
                _msg := 'Could not find entry in database for parameter file "' || _paramFileName || '"';
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Validate the settings file name
        ---------------------------------------------------
        --
        If _settingsFileName <> 'na' Then
            If Not Exists (SELECT * FROM t_settings_files WHERE file_name = _settingsFileName) Then
                _msg := 'Could not find entry in database for settings file "' || _settingsFileName || '"';
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Check protein parameters
        ---------------------------------------------------

        _ownerUsername := '';

        Call validate_protein_collection_params (
                    _analysisToolName,
                    _organismDBName      => _organismDBName,        -- Output
                    _organismName        => _organismName,
                    _protCollNameList    => _protCollNameList,      -- Output
                    _protCollOptionsList => _protCollOptionsList,   -- Output
                    _ownerUsername       => _ownerUsername,
                    _message             => _message,               -- Output
                    _returnCode          => _returnCode,            -- Output
                    _debugMode           => _showDebugMessages);

        If _returnCode <> '' Then
            _msg := _message;
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- _creator should be a userUsername
        -- Auto-capitalize it or auto-resolve it from a name to a username
        ---------------------------------------------------

        _userID := public.get_user_id (_creator);

        If _userID > 0 Then
            -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _creator contains simply the username
            --
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

            Call auto_resolve_name_to_username (_creator, _matchCount => _matchCount, _matchingUsername => _newUsername, _matchingUserID => _userID);

            If _matchCount = 1 Then
                -- Single match was found; update _creator
                _creator := _newUsername;
            End If;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then

            -- Cannot update a non-existent entry
            --
            SELECT predefine_id
            INTO _tmp
            FROM  t_predefined_analysis
            WHERE (predefine_id = _id)

            If Not FOUND Then
                _msg := 'No entry could be found in database for update';
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
                instrument_class_criteria,
                campaign_name_criteria,
                campaign_excl_criteria,
                experiment_name_criteria,
                experiment_excl_criteria,
                instrument_name_criteria,
                instrument_excl_criteria,
                organism_name_criteria,
                dataset_name_criteria,
                dataset_excl_criteria,
                dataset_type_criteria,
                exp_comment_criteria,
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
                special_processing,
                enabled,
                description,
                creator,
                next_level,
                trigger_before_disposition,
                propagation_mode,
                last_affected
            ) VALUES (
                _level,
                _seqVal,
                _instrumentClassCriteria,
                _campaignNameCriteria,
                _campaignExclCriteria,
                _experimentNameCriteria,
                _experimentExclCriteria,
                _instrumentNameCriteria,
                _instrumentExclCriteria,
                _organismNameCriteria,
                _datasetNameCriteria,
                _datasetExclCriteria,
                _datasetTypeCriteria,
                _expCommentCriteria,
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
                _specialProcessing,
                _enabled,
                _description,
                _creator,
                _nextLevelVal,
                Coalesce(_triggerBeforeDisposition, 0),
                _propMode,
                CURRENT_TIMESTAMP
            )
            RETURNING predefine_id
            INTO _id;

        End If; -- add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If _mode = 'update' Then

            UPDATE t_predefined_analysis
            SET
                predefine_level = _level,
                predefine_sequence = _seqVal,
                instrument_class_criteria = _instrumentClassCriteria,
                campaign_name_criteria = _campaignNameCriteria,
                campaign_excl_criteria = _campaignExclCriteria,
                experiment_name_criteria = _experimentNameCriteria,
                experiment_excl_criteria = _experimentExclCriteria,
                instrument_name_criteria = _instrumentNameCriteria,
                instrument_excl_criteria = _instrumentExclCriteria,
                organism_name_criteria = _organismNameCriteria,
                dataset_name_criteria = _datasetNameCriteria,
                dataset_excl_criteria = _datasetExclCriteria,
                dataset_type_criteria = _datasetTypeCriteria,
                exp_comment_criteria = _expCommentCriteria,
                labelling_incl_criteria = _labellingInclCriteria,
                labelling_excl_criteria = _labellingExclCriteria,
                separation_type_criteria = _separationTypeCriteria,
                analysis_tool_name = _analysisToolName,
                param_file_name = _paramFileName,
                settings_file_name = _settingsFileName,
                organism_id = _organismID,
                organism_db_name = _organismDBName,
                protein_collection_list = _protCollNameList,
                protein_options_list = _protCollOptionsList,
                priority = _priority,
                special_processing = _specialProcessing,
                enabled = _enabled,
                description = _description,
                creator = _creator,
                next_level = _nextLevelVal,
                trigger_before_disposition = Coalesce(_triggerBeforeDisposition, 0),
                propagation_mode = _propMode,
                last_affected = CURRENT_TIMESTAMP
            WHERE (predefine_id = _id);

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('%s; Job %s', _exceptionMessage, _job);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    DROP TABLE IF EXISTS Tmp_MatchingInstruments;
END
$$;

COMMENT ON PROCEDURE public.add_update_predefined_analysis IS 'AddUpdatePredefinedAnalysis';