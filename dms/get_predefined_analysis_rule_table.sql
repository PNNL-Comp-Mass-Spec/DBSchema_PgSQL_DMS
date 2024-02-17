--
-- Name: get_predefined_analysis_rule_table(text, text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_predefined_analysis_rule_table(_datasetname text, _analysistoolnamefilter text DEFAULT ''::text, _ignoredatasetrating boolean DEFAULT false) RETURNS TABLE(message public.citext, predefine_id integer, predefine_level integer, predefine_sequence integer, instrument_class_criteria public.citext, campaign_name_criteria public.citext, campaign_excl_criteria public.citext, experiment_name_criteria public.citext, experiment_excl_criteria public.citext, exp_comment_criteria public.citext, instrument_name_criteria public.citext, instrument_excl_criteria public.citext, organism_name_criteria public.citext, dataset_name_criteria public.citext, dataset_excl_criteria public.citext, dataset_type_criteria public.citext, scan_type_criteria public.citext, scan_type_excl_criteria public.citext, labelling_incl_criteria public.citext, labelling_excl_criteria public.citext, separation_type_criteria public.citext, scan_count_min_criteria integer, scan_count_max_criteria integer, analysis_tool_name public.citext, param_file_name public.citext, settings_file_name public.citext, organism_id integer, organism public.citext, protein_collection_list public.citext, protein_options_list public.citext, organism_db_name public.citext, priority integer, next_level integer, trigger_before_disposition smallint, propagation_mode smallint, special_processing public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**     Return a table of predefined analysis rules for given dataset
**
**     If the dataset name is invalid, or if no predefine rules are defined, returns a table with a warning in the message column (other columns will be empty)
**
**  Arguments:
**    _datasetName                      Dataset to evaluate
**    _analysisToolNameFilter           If not blank, only consider predefines that match the given tool name (can contain wildcards)
**    _ignoreDatasetRating              When true, ignore Trigger_Before_Disposition and dataset rating; this is useful when previewing rules (via mode 'Show Rules')
**
**  Auth:   mem
**  Date:   11/08/2022 mem - Initial version (refactored code from evaluate_predefined_analysis_rules)
**          05/30/2023 mem - Use format() for string concatenation
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/08/2023 mem - Add support for scan type inclusion or exclusion
**
*****************************************************/
DECLARE
    _predefineInfo record;
    _message citext;
BEGIN
    _message := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetName            := Trim(Coalesce(_datasetName, ''));
    _analysisToolNameFilter := Trim(Coalesce(_analysisToolNameFilter, ''));
    _ignoreDatasetRating    := Coalesce(_ignoreDatasetRating, false);

    ---------------------------------------------------
    -- Get evaluation information for this dataset
    ---------------------------------------------------

    SELECT DS.Campaign,
           DS.Experiment,
           DS.Experiment_Comment AS ExperimentComment,
           DS.Experiment_Labelling AS ExperimentLabelling,
           DS.Dataset,
           DS.Dataset_Type AS DatasetType,
           DS.Scan_Types AS ScanTypes,
           DS.Separation_Type AS SeparationType,
           DS.Organism,
           DS.Instrument AS InstrumentName,
           DS.Instrument_Class AS InstrumentClass,
           DS.Dataset_Comment AS DatasetComment,
           DS.Rating,
           DS.Scan_Count AS ScanCount,
           DS.ID
    INTO _predefineInfo
    FROM V_Predefined_Analysis_Dataset_Info DS
    WHERE DS.Dataset = _datasetName::citext;

    If Not FOUND Then
        _message := format('Dataset not found in DMS: %s', _datasetName);
    Else

        RETURN QUERY
        SELECT ''::citext AS message,
               PA.predefine_id,
               PA.predefine_level,
               PA.predefine_sequence,
               PA.instrument_class_criteria,
               PA.campaign_name_criteria,
               PA.campaign_excl_criteria,
               PA.experiment_name_criteria,
               PA.experiment_excl_criteria,
               PA.exp_comment_criteria,
               PA.instrument_name_criteria,
               PA.instrument_excl_criteria,
               PA.organism_name_criteria,
               PA.dataset_name_criteria,
               PA.dataset_excl_criteria,
               PA.dataset_type_criteria,
               PA.scan_type_criteria,
               PA.scan_type_excl_criteria,
               PA.labelling_incl_criteria,
               PA.labelling_excl_criteria,
               PA.separation_type_criteria,
               PA.scan_count_min_criteria,
               PA.scan_count_max_criteria,
               PA.analysis_tool_name,
               PA.param_file_name,
               PA.settings_file_name,
               Org.organism_id,
               Org.organism,
               PA.protein_collection_list,
               PA.protein_options_list,
               PA.organism_db_name,
               PA.priority,
               PA.next_level,
               PA.trigger_before_disposition,
               PA.propagation_mode,
               PA.special_processing
        FROM t_predefined_analysis PA INNER JOIN
             t_organisms Org ON PA.organism_id = Org.organism_id
        WHERE (PA.enabled > 0)
            AND ((_predefineInfo.InstrumentClass         SIMILAR TO PA.instrument_class_criteria) OR PA.instrument_class_criteria = '')
            AND ((_predefineInfo.InstrumentName          SIMILAR TO PA.instrument_name_criteria)  OR PA.instrument_name_criteria = '')
            AND (NOT (_predefineInfo.InstrumentName      SIMILAR TO PA.instrument_excl_criteria)  OR PA.instrument_excl_criteria = '')
            AND ((_predefineInfo.Campaign                SIMILAR TO PA.campaign_name_criteria)    OR PA.campaign_name_criteria = '')
            AND (NOT (_predefineInfo.Campaign            SIMILAR TO PA.campaign_excl_criteria)    OR PA.campaign_excl_criteria = '')
            AND ((_predefineInfo.Experiment              SIMILAR TO PA.experiment_name_criteria)  OR PA.experiment_name_criteria = '')
            AND (NOT (_predefineInfo.Experiment          SIMILAR TO PA.experiment_excl_criteria)  OR PA.experiment_excl_criteria = '')
            AND ((_predefineInfo.ExperimentComment       SIMILAR TO PA.exp_comment_criteria)      OR PA.exp_comment_criteria = '')
            AND ((_predefineInfo.Dataset                 SIMILAR TO PA.dataset_name_criteria)     OR PA.dataset_name_criteria = '')
            AND (NOT (_predefineInfo.Dataset             SIMILAR TO PA.dataset_excl_criteria)     OR PA.dataset_excl_criteria = '')
            AND ((_predefineInfo.DatasetType             SIMILAR TO PA.dataset_type_criteria)     OR PA.dataset_type_criteria = '')
            AND ((_predefineInfo.ScanTypes               SIMILAR TO PA.scan_type_criteria)        OR PA.scan_type_criteria = '')
            AND (NOT (_predefineInfo.ScanTypes           SIMILAR TO PA.scan_type_excl_criteria)   OR PA.scan_type_excl_criteria = '')
            AND ((_predefineInfo.ExperimentLabelling     SIMILAR TO PA.labelling_incl_criteria)   OR PA.labelling_incl_criteria = '')
            AND (NOT (_predefineInfo.ExperimentLabelling SIMILAR TO PA.labelling_excl_criteria)   OR PA.labelling_excl_criteria = '')
            AND ((_predefineInfo.SeparationType          SIMILAR TO PA.separation_type_criteria)  OR PA.separation_type_criteria = '')
            AND ((_predefineInfo.Organism                SIMILAR TO PA.organism_name_criteria)    OR PA.organism_name_criteria = '')
            AND (
                  -- Note that we always create jobs for predefines with Trigger_Before_Disposition = 1
                  -- Procedure schedule_predefined_analysis_jobs will typically be called with _preventDuplicateJobs = true so duplicate jobs will not get created after a dataset is reviewed
                 (PA.Trigger_Before_Disposition = 1) OR
                 (_predefineInfo.Rating <> -10 AND PA.Trigger_Before_Disposition = 0) OR
                 (_ignoreDatasetRating)
                )
            AND ((PA.analysis_tool_name SIMILAR TO _analysisToolNameFilter) OR _analysisToolNameFilter = '')
            AND ((PA.scan_count_min_criteria <= 0 AND PA.scan_count_max_criteria <= 0) OR
                 (_predefineInfo.ScanCount BETWEEN PA.scan_count_min_criteria AND PA.scan_count_max_criteria));

        If Not FOUND Then
            _message := 'No rules found';

            If _predefineInfo.Rating = -10 Then
                _message := format('%s (dataset is unreviewed)', _message);
            End If;

            _message := format('%s: %s', _message, _datasetName);
        End If;
    End If;

    If _message <> '' Then
        RETURN QUERY
        SELECT _message,
               0          AS predefine_id,
               0          AS predefine_level,
               0          AS predefine_sequence,
               ''::citext AS instrument_class_criteria,
               ''::citext AS campaign_name_criteria,
               ''::citext AS campaign_excl_criteria,
               ''::citext AS experiment_name_criteria,
               ''::citext AS experiment_excl_criteria,
               ''::citext AS exp_comment_criteria,
               ''::citext AS instrument_name_criteria,
               ''::citext AS instrument_excl_criteria,
               ''::citext AS organism_name_criteria,
               ''::citext AS dataset_name_criteria,
               ''::citext AS dataset_excl_criteria,
               ''::citext AS dataset_type_criteria,
               ''::citext AS scan_type_criteria,
               ''::citext AS scan_type_excl_criteria,
               ''::citext AS labelling_incl_criteria,
               ''::citext AS labelling_excl_criteria,
               ''::citext AS separation_type_criteria,
               0          AS scan_count_min_criteria,
               0          AS scan_count_max_criteria,
               ''::citext AS analysis_tool_name,
               ''::citext AS param_file_name,
               ''::citext AS settings_file_name,
               0          AS organism_id,
               ''::citext AS organism,
               ''::citext AS protein_collection_list,
               ''::citext AS protein_options_list,
               ''::citext AS organism_db_name,
               0          AS priority,
               0          AS next_level,
               0::int2    AS trigger_before_disposition,
               0::int2    AS propagation_mode,
               ''::citext AS special_processing;
    End If;
END
$$;


ALTER FUNCTION public.get_predefined_analysis_rule_table(_datasetname text, _analysistoolnamefilter text, _ignoredatasetrating boolean) OWNER TO d3l243;

