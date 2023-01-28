--
-- Name: predefined_analysis_jobs_mds_proc(text, refcursor, text, text, boolean, boolean, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.predefined_analysis_jobs_mds_proc(IN _datasetlist text, IN _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _excludedatasetsnotreleased boolean DEFAULT true, IN _createjobsforunrevieweddatasets boolean DEFAULT true, IN _analysistoolnamefilter text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**     Evaluate predefined analysis rules for given list of datasets
**     Use a cursor to return the list of jobs that would be created
**
**  Arguments:
**    _datasetList                      Comma separated list of dataset names
**    _excludeDatasetsNotReleased       When true, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
**    _createJobsForUnreviewedDatasets  When true, will create jobs for datasets with a rating of -10 using predefines with Trigger_Before_Disposition = 1
**    _analysisToolNameFilter           If not blank, only considers predefines that match the given tool name (can contain wildcards)
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL public.predefined_analysis_jobs_mds_proc (
**              _datasetList => 'QC_Mam_19_01_d_09Aug22_Pippin_WBEH-22-02-04-50u, QC_Mam_19_01_a_09Aug22_Pippin_WBEH-22-02-04-50u, QC_Mam_19_01_Run-1_09Aug22_Oak_WBEH_22-06-17'
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Auth:   mem
**  Date:   11/09/2022 mem - Initial version
**          01/26/2023 mem - Include Predefine_ID in the query results
**          01/27/2023 mem - Include ID column in the query results
**                         - Show legacy FASTA file name after the protein collection info
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

    _datasetList := Coalesce(_datasetList, '');
    _excludeDatasetsNotReleased := Coalesce(_excludeDatasetsNotReleased, true);
    _createJobsForUnreviewedDatasets := Coalesce(_createJobsForUnreviewedDatasets, true);
    _analysisToolNameFilter := Coalesce(_analysisToolNameFilter, '');

    DROP TABLE If Exists Tmp_PredefinedAnalysisJobResults;

    CREATE TEMP TABLE Tmp_PredefinedAnalysisJobResults (
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
        owner_prn text,
        comment text,
        propagation_mode smallint,
        special_processing citext,
        id int,
        existing_job_count int,
        message text,
        returncode text
    );

    INSERT INTO Tmp_PredefinedAnalysisJobResults (
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
        owner_prn,
        comment,
        propagation_mode,
        special_processing,
        id,
        existing_job_count,
        message,
        returncode
    )
    SELECT predefine_id,
           dataset,
           priority,
           analysis_tool_name,
           param_file_name,
           settings_file_name,
           organism_name,
           protein_collection_list,
           protein_options_list,
           organism_db_name,
           owner_prn,
           comment,
           propagation_mode,
           special_processing,
           id,                         -- GENERATED ALWAYS AS IDENTITY column
           existing_job_count,
           message,
           returncode
    FROM public.predefined_analysis_jobs_mds(
            _datasetList,
            _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
            _createJobsForUnreviewedDatasets => _createJobsForUnreviewedDatasets,
            _analysisToolNameFilter => _analysisToolNameFilter);

    If Not FOUND Then
        _message := format('Function predefined_analysis_jobs_mds did not return any results for datasets %s', _datasetList);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
    End If;

    If _returnCode = '' And Not Exists (SELECT * FROM Tmp_PredefinedAnalysisJobResults WHERE id > 0) Then
        SELECT message
        INTO _message
        FROM Tmp_PredefinedAnalysisJobResults
        WHERE id <= 0
        LIMIT 1;

        _returnCode := 'U5202';
    End If;

    If _returnCode = '' Then
        Open _results For
            SELECT
                id,
                'Entry' AS job,
                predefine_id,
                dataset,
                existing_job_count AS jobs,
                analysis_tool_name AS tool,
                priority AS pri,
                comment,
                param_file_name AS param_file,
                settings_file_name AS settings_file,
                organism_name AS organism,
                protein_collection_list AS protein_collections,
                protein_options_list AS protein_options,
                organism_db_name,
                special_processing,
                owner_prn AS owner,
                CASE propagation_mode WHEN 0 THEN 'Export' ELSE 'No Export' END AS export_mode
            FROM Tmp_PredefinedAnalysisJobResults
            WHERE id > 0;
    Else
        Open _results For
            SELECT
                id,
                'Entry' AS job,
                predefine_id
                dataset,
                existing_job_count AS jobs,
                analysis_tool_name AS tool,
                priority AS pri,
                comment,
                param_file_name AS param_file,
                settings_file_name AS settings_file,
                organism_name AS organism,
                protein_collection_list AS protein_collections,
                protein_options_list AS protein_options,
                organism_db_name,
                special_processing,
                owner_prn AS owner,
                CASE propagation_mode WHEN 0 THEN 'Export' ELSE 'No Export' END AS export_mode
            FROM Tmp_PredefinedAnalysisJobResults;
    End If;

    RETURN;

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

END;
$$;


ALTER PROCEDURE public.predefined_analysis_jobs_mds_proc(IN _datasetlist text, IN _results refcursor, INOUT _message text, INOUT _returncode text, IN _excludedatasetsnotreleased boolean, IN _createjobsforunrevieweddatasets boolean, IN _analysistoolnamefilter text) OWNER TO d3l243;

