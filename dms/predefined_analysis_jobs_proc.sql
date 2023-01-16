--
-- Name: predefined_analysis_jobs_proc(text, refcursor, text, text, boolean, boolean, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.predefined_analysis_jobs_proc(IN _datasetname text, IN _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _excludedatasetsnotreleased boolean DEFAULT true, IN _createjobsforunrevieweddatasets boolean DEFAULT true, IN _analysistoolnamefilter text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Evaluate predefined analysis rules for given dataset
**      Use a cursor to return the list of jobs that would be created
**
**  Arguments:
**    _datasetName                      Dataset to evaluate
**    _excludeDatasetsNotReleased       When true, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
**    _createJobsForUnreviewedDatasets  When true, will create jobs for datasets with a rating of -10 using predefines with Trigger_Before_Disposition = 1
**    _analysisToolNameFilter           If not blank, only considers predefines that match the given tool name (can contain wildcards)
**
**  Use this to view the data returned by the _results cursor
**
**      BEGIN;
**          CALL public.predefined_analysis_jobs_proc (
**              _datasetName => 'QC_Mam_19_01_d_09Aug22_Pippin_WBEH-22-02-04-50u'
**          );
**          FETCH ALL FROM _results;
**      END;
**
**  Auth:   mem
**  Date:   11/08/2022 mem - Initial version
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

    _datasetName := Coalesce(_datasetName, '');
    _excludeDatasetsNotReleased := Coalesce(_excludeDatasetsNotReleased, true);
    _createJobsForUnreviewedDatasets := Coalesce(_createJobsForUnreviewedDatasets, true);
    _analysisToolNameFilter := Coalesce(_analysisToolNameFilter, '');

    DROP TABLE If Exists Tmp_PredefinedAnalysisJobResults;

    CREATE TEMP TABLE Tmp_PredefinedAnalysisJobResults (
        dataset text,
        priority int,
        analysis_tool_name citext,
        param_file_name citext,
        settings_file_name citext,
        organism_db_name citext,
        organism_name citext,
        protein_collection_list citext,
        protein_options_list citext,
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
        dataset,
        priority,
        analysis_tool_name,
        param_file_name,
        settings_file_name,
        organism_db_name,
        organism_name,
        protein_collection_list,
        protein_options_list,
        owner_prn,
        comment,
        propagation_mode,
        special_processing,
        id,
        existing_job_count,
        message,
        returncode
    )
    SELECT  dataset,
            priority,
            analysis_tool_name,
            param_file_name,
            settings_file_name,
            organism_db_name,
            organism_name,
            protein_collection_list,
            protein_options_list,
            owner_prn,
            comment,
            propagation_mode,
            special_processing,
            id,
            existing_job_count,
            message,
            returncode
        FROM public.predefined_analysis_jobs(
                _datasetName,
                _raiseErrorMessages => true,
                _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                _createJobsForUnreviewedDatasets => _createJobsForUnreviewedDatasets,
                _analysisToolNameFilter => _analysisToolNameFilter);

    If Not FOUND Then
        _message := format('Function predefined_analysis_jobs did not return any results for dataset %s', _datasetName);
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
                'Entry' AS Job,
                dataset,
                existing_job_count AS Jobs,
                analysis_tool_name AS Tool,
                priority AS Pri,
                comment,
                param_file_name AS Param_File,
                settings_file_name AS Settings_File,
                organism_db_name AS OrganismDB_File,
                organism_name AS Organism,
                protein_collection_list AS Protein_Collections,
                protein_options_list AS Protein_Options,
                owner_prn AS Owner,
                CASE propagation_mode WHEN 0 THEN 'Export' ELSE 'No Export' END AS Export_Mode,
                special_processing AS Special_Processing
            FROM Tmp_PredefinedAnalysisJobResults
            WHERE id > 0;
    Else
        Open _results For
            SELECT
                'Entry' AS Job,
                dataset,
                existing_job_count AS Jobs,
                analysis_tool_name AS Tool,
                priority AS Pri,
                comment,
                param_file_name AS Param_File,
                settings_file_name AS Settings_File,
                organism_db_name AS OrganismDB_File,
                organism_name AS Organism,
                protein_collection_list AS Protein_Collections,
                protein_options_list AS Protein_Options,
                owner_prn AS Owner,
                CASE propagation_mode WHEN 0 THEN 'Export' ELSE 'No Export' END AS Export_Mode,
                special_processing AS Special_Processing
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


ALTER PROCEDURE public.predefined_analysis_jobs_proc(IN _datasetname text, IN _results refcursor, INOUT _message text, INOUT _returncode text, IN _excludedatasetsnotreleased boolean, IN _createjobsforunrevieweddatasets boolean, IN _analysistoolnamefilter text) OWNER TO d3l243;

