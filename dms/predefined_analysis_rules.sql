--
-- Name: predefined_analysis_rules(text, boolean, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.predefined_analysis_rules(_datasetname text, _excludedatasetsnotreleased boolean DEFAULT true, _analysistoolnamefilter text DEFAULT ''::text) RETURNS TABLE(step integer, level integer, seq integer, predefine_id integer, next_lvl integer, trigger_mode text, export_mode text, action text, reason text, notes text, analysis_tool text, instrument_class_criteria public.citext, instrument_criteria public.citext, instrument_exclusion public.citext, campaign_criteria public.citext, campaign_exclusion public.citext, experiment_criteria public.citext, experiment_exclusion public.citext, organism_criteria public.citext, dataset_criteria public.citext, dataset_exclusion public.citext, dataset_type public.citext, exp_comment_criteria public.citext, labelling_inclusion public.citext, labelling_exclusion public.citext, separation_type_criteria public.citext, scan_count_min integer, scan_count_max integer, param_file text, settings_file text, organism text, protein_collections text, protein_options text, organism_db text, special_processing text, priority integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return a table listing the predefined analysis rules that would be evaulated for the given dataset
**
**  Arguments:
**    _datasetName                      Dataset to evaluate
**    _excludeDatasetsNotReleased       When true, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
**    _analysisToolNameFilter           If not blank, only considers predefines that match the given tool name (can contain wildcards)
**
**  Auth:   mem
**          11/08/2022 mem - Initial version
**          01/27/2023 mem - Show legacy FASTA file name after the protein collection info
**                         - Rename columns in the query results
**          02/08/2023 mem - Switch from PRN to username
**
*****************************************************/
DECLARE
    _message text;

    _datasetID int;
    _datasetRating smallint;
    _datasetType text;
    _instrumentName text;
    _instrumentClass text;

    _minLevel int;
    _minLevelNew int;
    _predefineFound boolean;
    _predefineID int;
BEGIN
    _message := '';

    _datasetName := Coalesce(_datasetName, '');
    _excludeDatasetsNotReleased := Coalesce(_excludeDatasetsNotReleased, true);
    _analysisToolNameFilter := Coalesce(_analysisToolNameFilter, '');

    ---------------------------------------------------
    ---------------------------------------------------
    -- Rule selection section
    ---------------------------------------------------
    ---------------------------------------------------

    ---------------------------------------------------
    -- Get evaluation information for this dataset
    ---------------------------------------------------

    SELECT DS.id, DS.rating, DS.dataset_type, DS.instrument, DS.instrument_class
    INTO _datasetID, _datasetRating, _datasetType, _instrumentName, _instrumentClass
    FROM V_Predefined_Analysis_Dataset_Info DS
    WHERE DS.Dataset = _datasetName::citext;

    If Not FOUND Then
        _message := 'Dataset name not found in DMS: ' || _datasetName;

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    -- Only perform the following checks if the rating is less than 2
    If _datasetRating < 2 AND _datasetRating <> -10 Then

        If Not _excludeDatasetsNotReleased And _datasetRating IN (-4, -5, -6) Then
            -- Allow the jobs to be created
            _message := '';
        Else
            If _datasetRating IN (-4, -6) Then
                -- Either Rating is -4 (Not released, allow analysis)
                -- or     Rating is -6 (Not released, good data)
                -- Allow the jobs to be created
                _message := '';
            Else
                -- Do not allow the jobs to be created
                _message := format('Dataset rating (%s) does not allow creation of jobs: %s', _datasetRating, _datasetName);

                RAISE INFO '%', _message;
                RETURN;
            End If;
        End If;
    End If;

    ---------------------------------------------------
    -- Create temporary table to hold evaluation criteria
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Criteria (
        message citext,
        predefine_id int,
        predefine_level int NOT NULL,
        predefine_sequence int NULL,
        instrument_class_criteria citext NOT NULL,
        campaign_name_criteria citext NOT NULL,
        campaign_excl_criteria citext NOT NULL,
        experiment_name_criteria citext NOT NULL,
        experiment_excl_criteria citext NOT NULL,
        instrument_name_criteria citext NOT NULL,
        instrument_excl_criteria citext NOT NULL,
        organism_name_criteria citext NOT NULL,
        dataset_name_criteria citext NOT NULL,
        dataset_excl_criteria citext NOT NULL,
        dataset_type_criteria citext NOT NULL,
        exp_comment_criteria citext NOT NULL,
        labelling_incl_criteria citext NOT NULL,
        labelling_excl_criteria citext NOT NULL,
        separation_type_criteria citext NOT NULL,
        scan_count_min_criteria int NOT NULL,
        scan_count_max_criteria int NOT NULL,
        analysis_tool_name citext NOT NULL,
        param_file_name citext NOT NULL,
        settings_file_name citext NULL,
        organism_id int NOT NULL,
        organism citext NOT NULL,
        protein_collection_list citext NOT NULL,
        protein_options_list citext NOT NULL,
        organism_db_name citext NOT NULL,
        priority int NOT NULL,
        next_level int NULL,
        trigger_before_disposition smallint NOT NULL,
        propagation_mode smallint NOT NULL,
        special_processing citext NULL
    );

    CREATE TEMP TABLE Tmp_PredefineRuleEval (
        Step int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Level int,
        Seq int NULL,
        Predefine_ID int,
        Next_Lvl int NULL,
        Trigger_Mode text NULL,
        Export_Mode text NULL,
        Action text NULL,
        Reason text NULL,
        Notes text NULL,
        Analysis_Tool text NULL,
        Instrument_Class_Criteria citext NULL,
        Instrument_Criteria citext NULL,
        Instrument_Exclusion citext NULL,
        Campaign_Criteria citext NULL,
        Campaign_Exclusion citext,
        Experiment_Criteria citext NULL,
        Experiment_Exclusion citext,
        Organism_Criteria citext NULL,
        Dataset_Criteria citext NULL,
        Dataset_Exclusion citext,
        Dataset_Type citext,
        Exp_Comment_Criteria citext,
        Labelling_Inclusion citext NULL,
        Labelling_Exclusion citext NULL,
        Separation_Type_Criteria citext NULL,
        Scan_Count_Min int NULL,
        Scan_Count_Max int NULL,
        Param_File text NULL,
        Settings_File text NULL,
        Organism text NULL,
        Protein_Collections text NULL,
        Protein_Options text NULL,
        Organism_DB text NULL,
        Special_Processing text NULL,
        Priority int NULL
    );

    ---------------------------------------------------
    -- Populate the rule holding table with rules
    -- that the target dataset satisfies
    ---------------------------------------------------

    INSERT INTO Tmp_Criteria (
        message,
        predefine_id,
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
        scan_count_min_criteria,
        scan_count_max_criteria,
        analysis_tool_name,
        param_file_name,
        settings_file_name,
        organism_id,
        organism,
        protein_collection_list,
        protein_options_list,
        organism_db_name,
        priority,
        next_level,
        trigger_before_disposition,
        propagation_mode,
        special_processing
    )
    SELECT
        Src.message,
        Src.predefine_id,
        Src.predefine_level,
        Src.predefine_sequence,
        Src.instrument_class_criteria,
        Src.campaign_name_criteria,
        Src.campaign_excl_criteria,
        Src.experiment_name_criteria,
        Src.experiment_excl_criteria,
        Src.instrument_name_criteria,
        Src.instrument_excl_criteria,
        Src.organism_name_criteria,
        Src.dataset_name_criteria,
        Src.dataset_excl_criteria,
        Src.dataset_type_criteria,
        Src.exp_comment_criteria,
        Src.labelling_incl_criteria,
        Src.labelling_excl_criteria,
        Src.separation_type_criteria,
        Src.scan_count_min_criteria,
        Src.scan_count_max_criteria,
        Src.analysis_tool_name,
        Src.param_file_name,
        Src.settings_file_name,
        Src.organism_id,
        Src.organism,
        Src.protein_collection_list,
        Src.protein_options_list,
        Src.organism_db_name,
        Src.priority,
        Src.next_level,
        Src.trigger_before_disposition,
        Src.propagation_mode,
        Src.special_processing
    FROM public.get_predefined_analysis_rule_table(
            _datasetName,
            _analysisToolNameFilter,
            _ignoreDatasetRating => true) Src;

    If Not FOUND Then
        RAISE WARNING 'Function get_predefined_analysis_rule_table did not return any results for dataset %', _datasetName;

        DROP TABLE Tmp_Criteria;
        DROP TABLE Tmp_PredefineRuleEval;
        RETURN;
    End If;

    If Not Exists (SELECT * FROM Tmp_Criteria WHERE Tmp_Criteria.predefine_id > 0) Then
        -- No rules were found (it is possible the dataset is unreviewed and no predefine rules allow for job creation for unreviewed datasets)

        SELECT message
        INTO _message
        FROM Tmp_Criteria
        LIMIT 1;

        If Not FOUND Or Coalesce(_message, '') = '' Then
            _message := format('No matching rules were found for dataset %s', _datasetName);
        End If;

        RAISE INFO '%', _message;

        DROP TABLE Tmp_Criteria;
        DROP TABLE Tmp_PredefineRuleEval;
        RETURN;
    End If;

    INSERT INTO Tmp_PredefineRuleEval (
        Level, Seq, Predefine_ID, Next_Lvl, Trigger_Mode, Export_Mode,
        Action, Reason,
        Notes, Analysis_Tool,
        Instrument_Class_Criteria, Instrument_Criteria, Instrument_Exclusion,
        Campaign_Criteria, Campaign_Exclusion,
        Experiment_Criteria, Experiment_Exclusion,
        Organism_Criteria,
        Dataset_Criteria, Dataset_Exclusion, Dataset_Type,
        Exp_Comment_Criteria,
        Labelling_Inclusion, Labelling_Exclusion,
        Separation_Type_Criteria,
        Scan_Count_Min, Scan_Count_Max,
        Param_File, Settings_File,
        Organism,
        Protein_Collections, Protein_Options,
        Organism_DB, Special_Processing,
        Priority)
    SELECT  C.predefine_level, C.predefine_sequence, C.predefine_id, C.next_level,
            CASE WHEN C.Trigger_Before_Disposition = 1
                 THEN 'Before Disposition'
                 ELSE 'Normal'
                 END AS Trigger_Mode,
            CASE C.Propagation_Mode WHEN 0
                 THEN 'Export'
                 ELSE 'No Export'
                 END AS Export_Mode,
            'Skip' AS Action,
            'Level skip' AS Reason,
            '' AS Notes,
            C.analysis_tool_name,
            C.instrument_class_criteria, C.instrument_name_criteria, C.instrument_excl_criteria,
            C.campaign_name_criteria, C.campaign_excl_criteria,
            C.experiment_name_criteria, C.experiment_excl_criteria,
            C.organism_name_criteria,
            C.dataset_name_criteria, C.dataset_excl_criteria, C.dataset_type_criteria,
            C.exp_comment_criteria,
            C.labelling_incl_criteria, C.labelling_excl_criteria,
            C.separation_type_criteria,
            C.scan_count_min_criteria, C.scan_count_max_criteria,
            C.param_file_name, C.settings_file_name,
            C.organism,
            C.protein_collection_list, C.protein_options_list,
            C.organism_db_name,
            C.Special_Processing,
            C.priority
    FROM Tmp_Criteria C
    ORDER BY C.predefine_level, C.predefine_sequence, C.predefine_id;

    ---------------------------------------------------
    ---------------------------------------------------
    -- Job Creation / Rule Evaluation Section
    ---------------------------------------------------
    ---------------------------------------------------

    ---------------------------------------------------
    -- Get list of jobs to create
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_PredefineJobsToCreate (
        predefine_id int,
        dataset text,
        priority int,
        analysis_tool_name citext,
        param_file_name citext,
        settings_file_name citext,
        organism_name citext,
        protein_collection_list citext,
        protein_options_list citext,
        organism_db_name citext,
        owner_username text,
        comment text,
        propagation_mode int2,
        special_processing citext,
        id int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    );

    ---------------------------------------------------
    -- cycle through all rules in the holding table
    -- in evaluation order applying precedence rules
    -- and creating jobs as appropriate
    ---------------------------------------------------

    _minLevel := 0;

    WHILE true
    LOOP
        ---------------------------------------------------
        -- Evaluate the next rule in the holding table
        ---------------------------------------------------
        CALL public.evaluate_predefined_analysis_rule(
                _minLevel => _minLevel,
                _datasetName => _datasetName,
                _instrumentName => _instrumentName,
                _instrumentClass => _instrumentClass,
                _datasetRating => _datasetRating,
                _datasetType => _datasetType,
                _previewingRules => true,
                _predefineFound => _predefineFound,         -- Output
                _predefineID => _predefineID,               -- Output
                _minLevelNew => _minLevelNew,               -- Output
                _message => _message);                      -- Output

        If Not _predefineFound Then
            -- Break out of the while loop
            EXIT;
        End If;

        _minLevel := _minLevelNew;

        ---------------------------------------------------
        -- Remove the rule from the holding table
        ---------------------------------------------------

        DELETE FROM Tmp_Criteria
        WHERE Tmp_Criteria.predefine_id = _predefineID;

    END LOOP;

    ---------------------------------------------------
    -- Return list of predefine rules that were evaluated
    ---------------------------------------------------

    RETURN QUERY
    SELECT
        Src.Step,
        Src.Level,
        Src.Seq,
        Src.Predefine_ID,
        Src.Next_Lvl,
        Src.Trigger_Mode,
        Src.Export_Mode,
        Src.Action,
        Src.Reason,
        Src.Notes,
        Src.Analysis_Tool,
        Src.Instrument_Class_Criteria,
        Src.Instrument_Criteria,
        Src.Instrument_Exclusion,
        Src.Campaign_Criteria,
        Src.Campaign_Exclusion,
        Src.Experiment_Criteria,
        Src.Experiment_Exclusion,
        Src.Organism_Criteria,
        Src.Dataset_Criteria,
        Src.Dataset_Exclusion,
        Src.Dataset_Type,
        Src.Exp_Comment_Criteria,
        Src.Labelling_Inclusion,
        Src.Labelling_Exclusion,
        Src.Separation_Type_Criteria,
        Src.Scan_Count_Min,
        Src.Scan_Count_Max,
        Src.Param_File,
        Src.Settings_File,
        Src.Organism,
        Src.Protein_Collections,
        Src.Protein_Options,
        Src.Organism_DB,
        Src.Special_Processing,
        Src.Priority
    FROM Tmp_PredefineRuleEval Src
    ORDER BY Src.Step;

    DROP TABLE Tmp_Criteria;
    DROP TABLE Tmp_PredefineJobsToCreate;

    DROP TABLE Tmp_PredefineRuleEval;

END
$$;


ALTER FUNCTION public.predefined_analysis_rules(_datasetname text, _excludedatasetsnotreleased boolean, _analysistoolnamefilter text) OWNER TO d3l243;

--
-- Name: FUNCTION predefined_analysis_rules(_datasetname text, _excludedatasetsnotreleased boolean, _analysistoolnamefilter text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.predefined_analysis_rules(_datasetname text, _excludedatasetsnotreleased boolean, _analysistoolnamefilter text) IS 'Implements modes "Show Rules" from EvaluatePredefinedAnalysisRules';

