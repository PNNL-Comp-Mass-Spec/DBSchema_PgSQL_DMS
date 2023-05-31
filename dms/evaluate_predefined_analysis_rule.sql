--
-- Name: evaluate_predefined_analysis_rule(integer, text, text, text, smallint, text, boolean, boolean, integer, integer, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.evaluate_predefined_analysis_rule(IN _minlevel integer, IN _datasetname text, IN _instrumentname text, IN _instrumentclass text, IN _datasetrating smallint, IN _datasettype text, IN _previewingrules boolean, INOUT _predefinefound boolean, INOUT _predefineid integer, INOUT _minlevelnew integer, INOUT _message text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Lookup the next rule in temporary table Tmp_Criteria with predefine_level >= _minLevel
**
**      If found, evaluate the rule's criteria against the dataset's attributes,
**      and append a new row to temporary table Tmp_PredefineJobsToCreate if the rules pass
**
**      If _previewingRules is true and a rule is found, also append a new row to temporary table Tmp_PredefineRuleEval
**
**      The calling method must create and populate temporary table Tmp_Criteria
**      If _previewingRules is true, it must also create temp table Tmp_PredefineRuleEval
**
**  Arguments:
**    _minLevel             Minimum rule level to match
**    _datasetName          Dataset name
**    _instrumentName       Instrument name
**    _instrumentClass      Instrument class
**    _datasetRating        Dataset rating
**    _datasetType          Dataset type
**    _previewingRules      Set to true if evaluating rules (and thus temp table Tmp_PredefineRuleEval exists)
**    _predefineFound       Output: true if a predefine analysis rule was found
**    _predefineID          Output: predefine_id of the rule (if found)
**    _minLevelNew          Output: new rule level to match the next time this procedure is called
**
**  Auth:   mem
**  Date:   11/08/2022 mem - Initial version
**          01/26/2023 mem - Store the Predefine ID in Tmp_PredefineJobsToCreate
**          01/27/2023 mem - Track legacy FASTA file name after the protein collection info
**          02/08/2023 mem - Switch from PRN to username
**          05/19/2023 mem - Remove redundant parentheses
**          05/30/2023 mem - Use append_to_text() for string concatenation
**
*****************************************************/
DECLARE
    _predefineInfo record;
    _useRule boolean;
    _ruleAction text;
    _ruleActionReason text;
    _ruleEvalNotes text;

    _comment text;
    _ownerUsername text;

    _schedulingRulePriority int;
    _schedulingRuleID int;
    _proteinCollectionListValidated text;
    _collectionCountAdded int;
BEGIN
    _message := '';

    _minLevel := Coalesce(_minLevel, 0);
    _minLevelNew := _minLevel;
    _predefineID := 0;

    SELECT
        predefine_id AS PredefineID,
        analysis_tool_name AS AnalysisToolName,
        param_file_name AS ParamFileName,
        settings_file_name AS SettingsFileName,
        organism AS OrganismName,
        protein_collection_list AS ProteinCollectionList,
        protein_options_list AS ProteinOptionsList,
        organism_db_name AS OrganismDBName,
        priority AS Priority,
        next_level AS RuleNextLevel,
        trigger_before_disposition AS TriggerBeforeDisposition,
        propagation_mode AS PropagationMode,
        special_processing AS SpecialProcessing
    INTO _predefineInfo
    FROM Tmp_Criteria
    WHERE predefine_level >= _minLevel
    ORDER BY predefine_level, predefine_sequence, predefine_id
    LIMIT 1;

    If Not FOUND Then
        _predefineFound := false;
        RETURN;
    End If;

    _predefineFound := true;
    _predefineID := _predefineInfo.PredefineID;

    _useRule := true;
    _ruleAction := 'Use';
    _ruleActionReason := 'Pass filters';
    _ruleEvalNotes := '';

    ---------------------------------------------------
    -- Validate that _datasetType is appropriate for this analysis tool
    ---------------------------------------------------
    --
    If Not Exists (
        SELECT *
        FROM t_analysis_tool_allowed_dataset_type ADT
             INNER JOIN t_analysis_tool Tool
               ON ADT.analysis_tool_id = Tool.analysis_tool_id
        WHERE Tool.analysis_tool = _predefineInfo.AnalysisToolName AND
              ADT.dataset_type = _datasetType::citext
        ) Then

        -- Dataset type is not allowed for this tool
        _useRule := false;
        _ruleAction := 'Skip';
        _ruleActionReason := format('Dataset type "%s" is not allowed for analysis tool %s', _datasetType, _predefineInfo.AnalysisToolName);

    End If;

    If _useRule Then
        If _datasetRating = -10 And _predefineInfo.TriggerBeforeDisposition = 0 Then
            _ruleAction := 'Skip';
            _ruleActionReason := 'Dataset is unreviewed';
            _useRule := false;
        End If;

    End If;

    If _useRule Then

        ---------------------------------------------------
        -- Evaluate rule precedence
        ---------------------------------------------------

        -- If there is a next level value for rule,
        -- Set minimum level to it
        --
        If NOT _predefineInfo.RuleNextLevel IS NULL Then
            _minLevelNew := _predefineInfo.RuleNextLevel;

            _ruleEvalNotes := public.append_to_text(_ruleEvalNotes, format('Next rule must have level >= %s', _predefineInfo.RuleNextLevel));
        End If;

        ---------------------------------------------------
        -- Override priority and/or assigned processor
        -- according to first scheduling rule in the evaluation
        -- sequence that applies to job being created
        ---------------------------------------------------

        SELECT
            priority,
            -- Obsolete: processor_group_id,
            rule_id
        INTO _schedulingRulePriority, _schedulingRuleID
        FROM t_predefined_analysis_scheduling_rules
        WHERE enabled > 0 AND
              (_instrumentClass::citext SIMILAR TO instrument_class          OR instrument_class   = '') AND
              (_instrumentName::citext  SIMILAR TO instrument_name           OR instrument_name    = '') AND
              (_datasetName::citext     SIMILAR TO dataset_name              OR dataset_name       = '') AND
              (_predefineInfo.AnalysisToolName SIMILAR TO analysis_tool_name OR analysis_tool_name = '')
        ORDER BY evaluation_order
        LIMIT 1;

        If FOUND Then
            _predefineInfo.Priority := Coalesce(_schedulingRulePriority, _predefineInfo.Priority);

            -- Obsolete
            -- If Coalesce(_tmpProcessorGroupID, 0) > 0 Then
            --     SELECT group_name
            --     INTO _associatedProcessorGroup
            --     FROM t_analysis_job_processor_group
            --     WHERE group_id = _tmpProcessorGroupID;
            --
            --     _associatedProcessorGroup := Coalesce(_associatedProcessorGroup, '');
            -- Else
            --     _associatedProcessorGroup := '';
            -- End If;

            -- Obsolete:
            -- If char_length(_associatedProcessorGroup) > 0 Then
            --     _ruleEvalNotes := public.append_to_text(_ruleEvalNotes, format('Processor group set to %s', _associatedProcessorGroup));
            -- End If;

            _ruleEvalNotes := public.append_to_text(_ruleEvalNotes,
                                                    format('Priority set to %s due to rule_id %s in t_predefined_analysis_scheduling_rules',
                                                            _predefineInfo.Priority, _schedulingRuleID));
        End If;

        ---------------------------------------------------
        -- Define the comment and job owner
        ---------------------------------------------------
        --
        _comment := format('Auto predefined %s', _predefineInfo.PredefineID);
        _ownerUsername := 'H09090911'; -- autouser

        ---------------------------------------------------
        -- Possibly auto-add tEnzyme-related protein collections to _predefineInfo.ProteinCollectionList
        ---------------------------------------------------
        --
        _proteinCollectionListValidated := Trim(Coalesce(_predefineInfo.ProteinCollectionList, ''));

        If char_length(_proteinCollectionListValidated) > 0 And public.validate_na_parameter(_proteinCollectionListValidated, 1) <> 'na' Then
            CALL validate_protein_collection_list_for_datasets (
                                _datasetName,
                                _protCollNameList => _proteinCollectionListValidated,   -- Output
                                _collectionCountAdded => _collectionCountAdded,         -- Output (unused, but required)
                                _message => _message,                                   -- Output
                                _showDebug => false);
        End If;

        ---------------------------------------------------
        -- Insert job into job holding table
        ---------------------------------------------------
        --
        -- Note that AddUpdateAnalysisJob will call ValidateAnalysisJobParameters to validate this data

        INSERT INTO Tmp_PredefineJobsToCreate (
            predefine_id,
            dataset,
            priority,
            analysis_tool_name,
            param_file_name,
            settings_file_name,
            organism_name,
            protein_collection_list,
            protein_options_list,
            organism_db_name,
            owner_username,
            comment,
            propagation_mode,
            special_processing
        ) VALUES (
            _predefineInfo.PredefineID,
            _datasetName,
            _predefineInfo.Priority,
            _predefineInfo.AnalysisToolName,
            _predefineInfo.ParamFileName,
            _predefineInfo.SettingsFileName,
            _predefineInfo.OrganismName,
            _proteinCollectionListValidated,
            _predefineInfo.ProteinOptionsList,
            _predefineInfo.OrganismDBName,
            _ownerUsername,
            _comment,
            _predefineInfo.PropagationMode,
            _predefineInfo.SpecialProcessing
        );

    End If;

    If _previewingRules Then
        UPDATE Tmp_PredefineRuleEval
        SET Action = _ruleAction,
            Reason = _ruleActionReason,
            Notes = _ruleEvalNotes,
            Priority = _predefineInfo.Priority
        WHERE Predefine_ID = _predefineInfo.PredefineID;
    End If;

END
$$;


ALTER PROCEDURE public.evaluate_predefined_analysis_rule(IN _minlevel integer, IN _datasetname text, IN _instrumentname text, IN _instrumentclass text, IN _datasetrating smallint, IN _datasettype text, IN _previewingrules boolean, INOUT _predefinefound boolean, INOUT _predefineid integer, INOUT _minlevelnew integer, INOUT _message text) OWNER TO d3l243;

