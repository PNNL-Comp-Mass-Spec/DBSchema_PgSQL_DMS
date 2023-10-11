--
-- Name: predefined_analysis_rules_proc(text, refcursor, text, text, boolean, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.predefined_analysis_rules_proc(IN _datasetname text, IN _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _excludedatasetsnotreleased boolean DEFAULT true, IN _analysistoolnamefilter text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get the predefined analysis rules for given dataset
**      Use a cursor to return the list of rules that would be evaluated
**
**  Arguments:
**    _datasetName                      Dataset to evaluate
**    _excludeDatasetsNotReleased       When true, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
**    _analysisToolNameFilter           If not blank, only considers predefines that match the given tool name (can contain wildcards)
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL public.predefined_analysis_rules_proc (
**              _datasetName => 'QC_Mam_19_01_d_09Aug22_Pippin_WBEH-22-02-04-50u'
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Auth:   mem
**  Date:   11/08/2022 mem - Initial version
**          01/27/2023 mem - Rename columns in the query results
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
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
            Step,
            Level,
            Seq,
            Predefine_ID,
            Next_Lvl,
            Trigger_Mode,
            Export_Mode,
            Action,
            Reason,
            Notes,
            Analysis_Tool,
            Instrument_Class_Criteria,
            Instrument_Criteria,
            Instrument_Exclusion,
            Campaign_Criteria,
            Campaign_Exclusion,
            Experiment_Criteria,
            Experiment_Exclusion,
            Organism_Criteria,
            Dataset_Criteria,
            Dataset_Exclusion,
            Dataset_Type,
            Exp_Comment_Criteria,
            Labelling_Inclusion,
            Labelling_Exclusion,
            Separation_Type_Criteria,
            Scan_Count_Min,
            Scan_Count_Max,
            Param_File,
            Settings_File,
            Organism,
            Protein_Collections,
            Protein_Options,
            Organism_DB,
            Special_Processing,
            Priority
        FROM public.predefined_analysis_rules(
                        _datasetName,
                        _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                        _analysisToolNameFilter     => _analysisToolNameFilter);

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


ALTER PROCEDURE public.predefined_analysis_rules_proc(IN _datasetname text, IN _results refcursor, INOUT _message text, INOUT _returncode text, IN _excludedatasetsnotreleased boolean, IN _analysistoolnamefilter text) OWNER TO d3l243;

