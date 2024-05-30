--
-- Name: predefined_analysis_jobs(text, boolean, boolean, boolean, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.predefined_analysis_jobs(_datasetname text, _raiseerrormessages boolean DEFAULT true, _excludedatasetsnotreleased boolean DEFAULT true, _createjobsforunrevieweddatasets boolean DEFAULT true, _analysistoolnamefilter text DEFAULT ''::text) RETURNS TABLE(predefine_id integer, dataset public.citext, priority integer, analysis_tool_name public.citext, param_file_name public.citext, settings_file_name public.citext, organism_name public.citext, protein_collection_list public.citext, protein_options_list public.citext, organism_db_name public.citext, owner_username public.citext, comment public.citext, propagation_mode smallint, special_processing public.citext, id integer, existing_job_count integer, message public.citext, returncode public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Evaluate predefined analysis rules for given dataset and return the list of jobs that would be created
**
**      Used by web page https://dms2.pnl.gov/predefined_analysis_jobs_preview/param
**      when it calls predefined_analysis_jobs_proc
**
**  Arguments:
**    _datasetName                      Dataset to evaluate
**    _raiseErrorMessages               When true, use RAISE WARNING to report warning messages
**    _excludeDatasetsNotReleased       When true, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
**    _createJobsForUnreviewedDatasets  When true, will create jobs for datasets with a rating of -10 using predefines with Trigger_Before_Disposition = 1
**    _analysisToolNameFilter           If not blank, only considers predefines that match the given tool name (can contain wildcards)
**
**  Usage:
**      SELECT * FROM predefined_analysis_jobs('QC_Mam_23_01-run2_TurboMSMS_09Jun23_Arwen_WBEH');
**      SELECT * FROM predefined_analysis_jobs('QC_Shew_21_01_10ng_nanoPOTS_26May23_WBEH_50_23_05_02_newSPE_FAIMS_3pt5_r2');
**
**  Auth:   grk
**  Date:   06/23/2005
**          03/03/2006 mem - Increased size of the AD_datasetNameCriteria and AD_expCommentCriteria fields in temporary table #AD
**          03/28/2006 grk - Added protein collection fields
**          04/04/2006 grk - Increased sized of param file name
**          11/30/2006 mem - Now evaluating dataset type for each analysis tool (Ticket #335)
**          12/21/2006 mem - Updated 'Show Rules' to include explanations for why a rule was used, altered, or skipped (Ticket #339)
**          01/26/2007 mem - Now getting organism name from T_Organisms (Ticket #368)
**          03/15/2007 mem - Replaced processor name with associated processor group (Ticket #388)
**          03/16/2007 mem - Updated to use processor group ID (Ticket #419)
**          09/04/2007 grk - Corrected bug in "_ruleEvalNotes" update.
**          12/28/2007 mem - Updated to allow preview of jobs for datasets with rating -10 (unreviewed)
**          01/04/2007 mem - Fixed bug that incorrectly allowed rules to be evaluated when rating = -10 and _outputType = 'Export Jobs'
**          01/30/2008 grk - Set several in Tmp_RuleEval to be explicitly null (needed by DMS2)
**          04/11/2008 mem - Added parameter _raiseErrorMessages; now using RaiseError to inform the user of errors if _raiseErrorMessages is true
**          08/06/2008 mem - Added new filter criteria: SeparationType, CampaignExclusion, ExperimentExclusion, and DatasetExclusion (Ticket #684)
**          05/14/2009 mem - Added parameter _excludeDatasetsNotReleased
**          07/22/2009 mem - Now returning 0 if _jobsCreated = 0 and _myError = 0 (previously, we were returning 1, which a calling procedure could erroneously interpret as meaning an error had occurred)
**          09/04/2009 mem - Added DatasetType filter
**          12/18/2009 mem - Now using T_Analysis_Tool_Allowed_Dataset_Type to determine valid dataset types for a given analysis tool
**          07/12/2010 mem - Now calling Validate_Protein_Collection_List_For_Datasets to validate the protein collection list (and possibly add mini proteome or enzyme-related protein collections)
**                         - Expanded protein Collection fields and variables to varchar(4000)
**          09/24/2010 mem - Now testing for a rating of -6 (Not Accepted)
**          11/18/2010 mem - Rearranged rating check code for clarity
**          02/09/2011 mem - Added support for predefines with Trigger_Before_Disposition = 1
**                         - Added parameter _createJobsForUnreviewedDatasets
**          02/16/2011 mem - Added support for Propagation Mode (aka Export Mode)
**          05/03/2012 mem - Added support for the Special Processing field
**          09/25/2012 mem - Expanded _organismName and _organismDBName to varchar(128)
**          08/02/2013 mem - Added parameter _analysisToolNameFilter
**          04/30/2015 mem - Added support for min and max ScanCount
**          04/21/2017 mem - Add AD_instrumentNameCriteria
**          10/05/2017 mem - Create jobs for datasets with rating -4: "Not released (allow analysis)"
**          08/29/2018 mem - Create jobs for datasets with rating -6: "Rerun (Good Data)"
**          06/30/2022 mem - Rename parameter file column
**          11/08/2022 mem - Ported to PostgreSQL
**          01/26/2023 mem - Include Predefine_ID in the query results
**          01/27/2023 mem - Show legacy FASTA file name after the protein collection info
**          02/08/2023 mem - Switch from PRN to username
**          02/23/2023 mem - Update procedure name in comments
**          05/22/2023 mem - Use format() for string concatenation
**          07/11/2023 mem - Use COUNT(job) instead of COUNT(*)
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/08/2023 mem - Add support for scan type inclusion or exclusion
**
*****************************************************/
DECLARE
    _message text;
    _returnCode text;

    _datasetID int;
    _datasetRating smallint;
    _datasetType text;
    _instrumentName text;
    _instrumentClass text;
    _existingJobCount int;

    _minLevel int;
    _minLevelNew int;
    _predefineFound boolean;
    _predefineID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetName                     := Trim(Coalesce(_datasetName, ''));
    _raiseErrorMessages              := Coalesce(_raiseErrorMessages, true);
    _excludeDatasetsNotReleased      := Coalesce(_excludeDatasetsNotReleased, true);
    _createJobsForUnreviewedDatasets := Coalesce(_createJobsForUnreviewedDatasets, true);
    _analysisToolNameFilter          := Trim(Coalesce(_analysisToolNameFilter, ''));

    ---------------------------------------------------
    -- Rule selection section
    --
    -- Get evaluation information for this dataset
    ---------------------------------------------------

    SELECT DS.id, DS.rating, DS.dataset_type, DS.instrument, DS.instrument_class
    INTO _datasetID, _datasetRating, _datasetType, _instrumentName, _instrumentClass
    FROM V_Predefined_Analysis_Dataset_Info DS
    WHERE DS.Dataset = _datasetName::citext;

    If Not FOUND Then
        _message := format('Dataset name not found in DMS: %s', _datasetName);

        If _raiseErrorMessages Then
            RAISE WARNING '%', _message;
        End If;

        _returnCode := 'U5350';
    End If;

    -- Only perform the following checks if the rating is less than 2
    If _returnCode = '' And _datasetRating < 2 Then

        If Not _excludeDatasetsNotReleased And _datasetRating In (-4, -5, -6) Then
            -- Allow the jobs to be created
            _message := '';
        Else
            If _datasetRating = -10 And _createJobsForUnreviewedDatasets Or _datasetRating In (-4, -6) Then
                -- Either the dataset is unreviewed, but _createJobsForUnreviewedDatasets is true
                -- or Rating is -4 (Not released, allow analysis)
                -- or Rating is -6 (Not released, good data)
                -- Allow the jobs to be created
                _message := '';
            Else
                -- Do not allow the jobs to be created
                -- Note that procedure create_predefined_analysis_jobs expects the format of _message to be something like:
                --   Dataset rating (-10) does not allow creation of jobs: 47538_Pls_FF_IGT_23_25Aug10_Andromeda_10-07-10
                -- Thus, be sure to update create_predefined_analysis_jobs if you change the following line
                _message := format('Dataset rating (%s) does not allow creation of jobs: %s', _datasetRating, _datasetName);

                If _raiseErrorMessages Then
                    RAISE INFO '%', _message;
                End If;

                _returnCode := 'U5351';
            End If;
        End If;
    End If;

    If _returnCode <> '' Then

        RETURN QUERY
        SELECT
            0,              -- predefine_id
            ''::citext,     -- dataset
            0,              -- priority
            ''::citext,     -- analysis_tool_name
            ''::citext,     -- param_file_name
            ''::citext,     -- settings_file_name
            ''::citext,     -- organism_name
            ''::citext,     -- protein_collection_list
            ''::citext,     -- protein_options_list
            ''::citext,     -- organism_db_name
            ''::citext,     -- owner_username
            ''::citext,     -- comment
            0::smallint,    -- propagation_mode
            ''::citext,     -- special_processing
            0,              -- id
            0,              -- existing_job_count
            _message::citext,
            _returnCode::citext;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Create temporary table to hold evaluation criteria
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Criteria (
        message                    citext,
        predefine_id               int,
        predefine_level            int NOT NULL,
        predefine_sequence         int NULL,
        instrument_class_criteria  citext NOT NULL,
        campaign_name_criteria     citext NOT NULL,
        campaign_excl_criteria     citext NOT NULL,
        experiment_name_criteria   citext NOT NULL,
        experiment_excl_criteria   citext NOT NULL,
        exp_comment_criteria       citext NOT NULL,
        instrument_name_criteria   citext NOT NULL,
        instrument_excl_criteria   citext NOT NULL,
        organism_name_criteria     citext NOT NULL,
        dataset_name_criteria      citext NOT NULL,
        dataset_excl_criteria      citext NOT NULL,
        dataset_type_criteria      citext NOT NULL,
        scan_type_criteria         citext NOT NULL,
        scan_type_excl_criteria    citext NOT NULL,
        labelling_incl_criteria    citext NOT NULL,
        labelling_excl_criteria    citext NOT NULL,
        separation_type_criteria   citext NOT NULL,
        scan_count_min_criteria    int NOT NULL,
        scan_count_max_criteria    int NOT NULL,
        analysis_tool_name         citext NOT NULL,
        param_file_name            citext NOT NULL,
        settings_file_name         citext NULL,
        organism_id                int NOT NULL,
        organism                   citext NOT NULL,
        protein_collection_list    citext NOT NULL,
        protein_options_list       citext NOT NULL,
        organism_db_name           citext NOT NULL,
        priority                   int NOT NULL,
        next_level                 int NULL,
        trigger_before_disposition smallint NOT NULL,
        propagation_mode           smallint NOT NULL,
        special_processing         citext NULL
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
        exp_comment_criteria,
        instrument_name_criteria,
        instrument_excl_criteria,
        organism_name_criteria,
        dataset_name_criteria,
        dataset_excl_criteria,
        dataset_type_criteria,
        scan_type_criteria,
        scan_type_excl_criteria,
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
        Src.exp_comment_criteria,
        Src.instrument_name_criteria,
        Src.instrument_excl_criteria,
        Src.organism_name_criteria,
        Src.dataset_name_criteria,
        Src.dataset_excl_criteria,
        Src.dataset_type_criteria,
        Src.scan_type_criteria,
        Src.scan_type_excl_criteria,
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
                    _ignoreDatasetRating => false) Src;

    If Not FOUND Then
        RAISE WARNING 'Function get_predefined_analysis_rule_table did not return any results for dataset %', _datasetName;

        DROP TABLE Tmp_Criteria;
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

        RETURN QUERY
        SELECT
            0,              -- predefine_id
            ''::citext,     -- dataset
            0,              -- priority
            ''::citext,     -- analysis_tool_name
            ''::citext,     -- param_file_name
            ''::citext,     -- settings_file_name
            ''::citext,     -- organism_name
            ''::citext,     -- protein_collection_list
            ''::citext,     -- protein_options_list
            ''::citext,     -- organism_db_name
            '',             -- owner_username
            '',             -- comment
            0,              -- num_jobs
            0::smallint,    -- propagation_mode
            ''::citext,     -- special_processing
            0,              -- id
            _message::citext,
            ''::citext AS returncode;

        DROP TABLE Tmp_Criteria;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Job Creation / Rule Evaluation Section
    --
    -- Get number of existing jobs for dataset
    ---------------------------------------------------

    SELECT COUNT(J.job)
    INTO _existingJobCount
    FROM t_analysis_job J
    WHERE J.dataset_id = _datasetID;

    ---------------------------------------------------
    -- Get list of jobs to create
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_PredefineJobsToCreate (
        predefine_id int,
        dataset citext,
        priority int,
        analysis_tool_name citext,
        param_file_name citext,
        settings_file_name citext,
        organism_name citext,
        protein_collection_list citext,
        protein_options_list citext,
        organism_db_name citext,
        owner_username citext,
        comment citext,
        propagation_mode smallint,
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
        -- Evaluate the next rule in the holding table (Tmp_Criteria)
        ---------------------------------------------------

        CALL public.evaluate_predefined_analysis_rule(
                _minLevel        => _minLevel,
                _datasetName     => _datasetName,
                _instrumentName  => _instrumentName,
                _instrumentClass => _instrumentClass,
                _datasetRating   => _datasetRating,
                _datasetType     => _datasetType,
                _previewingRules => false,
                _predefineFound  => _predefineFound,    -- Output
                _predefineID     => _predefineID,       -- Output
                _minLevelNew     => _minLevelNew,       -- Output
                _message         => _message);          -- Output

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
    -- Return list of jobs to create
    ---------------------------------------------------

    RETURN QUERY
    SELECT
        Src.predefine_id,
        Src.dataset,
        Src.priority,
        Src.analysis_tool_name,
        Src.param_file_name,
        Src.settings_file_name,
        Src.organism_name,
        Src.protein_collection_list,
        Src.protein_options_list,
        Src.organism_db_name,
        Src.owner_username,
        Src.comment,
        Src.propagation_mode,
        Src.special_processing,
        Src.id,
        _existingJobCount,
        ''::citext AS message,
        ''::citext AS returncode
    FROM Tmp_PredefineJobsToCreate Src
    ORDER BY Src.id;

    DROP TABLE Tmp_Criteria;
    DROP TABLE Tmp_PredefineJobsToCreate;
END
$$;


ALTER FUNCTION public.predefined_analysis_jobs(_datasetname text, _raiseerrormessages boolean, _excludedatasetsnotreleased boolean, _createjobsforunrevieweddatasets boolean, _analysistoolnamefilter text) OWNER TO d3l243;

--
-- Name: FUNCTION predefined_analysis_jobs(_datasetname text, _raiseerrormessages boolean, _excludedatasetsnotreleased boolean, _createjobsforunrevieweddatasets boolean, _analysistoolnamefilter text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.predefined_analysis_jobs(_datasetname text, _raiseerrormessages boolean, _excludedatasetsnotreleased boolean, _createjobsforunrevieweddatasets boolean, _analysistoolnamefilter text) IS 'Implements modes "Export Jobs" and "Show Jobs" from EvaluatePredefinedAnalysisRules';

