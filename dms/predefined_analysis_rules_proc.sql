--
-- Name: predefined_analysis_rules_proc(text, refcursor, text, text, boolean, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.predefined_analysis_rules_proc(IN _datasetname text, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _excludedatasetsnotreleased boolean DEFAULT true, IN _analysistoolnamefilter text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get the predefined analysis rules for given dataset
**
**      Used by web page https://dms2.pnl.gov/predefined_analysis_rules_preview/param
**
**  Arguments:
**    _datasetName                      Dataset to evaluate
**    _results                          Cursor for obtaining results
**    _message                          Status message
**    _returnCode                       Return code
**    _excludeDatasetsNotReleased       When true, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
**    _analysisToolNameFilter           If not blank, only considers predefines that match the given tool name (can contain wildcards)
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL public.predefined_analysis_rules_proc (
**              _datasetName => 'QC_Mam_19_01_d_09Aug22_Pippin_WBEH-22-02-04-50u',
**              _excludeDatasetsNotReleased => true
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Auth:   mem
**  Date:   11/08/2022 mem - Initial version
**          01/27/2023 mem - Rename columns in the query results
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          05/29/2024 mem - Change the _results parameter to INOUT (the DMS website can only retrieve the query results if it is an output parameter)
**                         - Set _returnResultIfNoRulesFound to true when querying predefined_analysis_rules()
**          08/08/2024 mem - Add columns scan_type_criteria and scan_type_exclusion
**
*****************************************************/
DECLARE
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _datasetName                := Trim(Coalesce(_datasetName, ''));
    _excludeDatasetsNotReleased := Coalesce(_excludeDatasetsNotReleased, true);
    _analysisToolNameFilter     := Trim(Coalesce(_analysisToolNameFilter, ''));

    Open _results For
        SELECT
            step,
            level,
            seq,
            predefine_id,
            next_lvl,
            trigger_mode,
            export_mode,
            action,
            reason,
            notes,
            analysis_tool,
            instrument_class_criteria,
            instrument_criteria,
            instrument_exclusion,
            campaign_criteria,
            campaign_exclusion,
            experiment_criteria,
            experiment_exclusion,
            organism_criteria,
            dataset_criteria,
            dataset_exclusion,
            dataset_type,
            scan_type_criteria,
            scan_type_exclusion,
            exp_comment_criteria,
            labelling_inclusion,
            labelling_exclusion,
            separation_type_criteria,
            scan_count_min,
            scan_count_max,
            param_file,
            settings_file,
            organism,
            protein_collections,
            protein_options,
            organism_db,
            special_processing,
            priority
        FROM public.predefined_analysis_rules(
                        _datasetName,
                        _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                        _analysisToolNameFilter     => _analysisToolNameFilter,
                        _returnResultIfNoRulesFound => true);

EXCEPTION
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
END
$$;


ALTER PROCEDURE public.predefined_analysis_rules_proc(IN _datasetname text, INOUT _results refcursor, INOUT _message text, INOUT _returncode text, IN _excludedatasetsnotreleased boolean, IN _analysistoolnamefilter text) OWNER TO d3l243;

