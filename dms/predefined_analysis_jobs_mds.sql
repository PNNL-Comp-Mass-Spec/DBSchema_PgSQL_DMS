--
-- Name: predefined_analysis_jobs_mds(text, boolean, boolean, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.predefined_analysis_jobs_mds(_datasetlist text, _excludedatasetsnotreleased boolean DEFAULT true, _createjobsforunrevieweddatasets boolean DEFAULT true, _analysistoolnamefilter text DEFAULT ''::text) RETURNS TABLE(predefine_id integer, dataset public.citext, priority integer, analysis_tool_name public.citext, param_file_name public.citext, settings_file_name public.citext, organism_name public.citext, protein_collection_list public.citext, protein_options_list public.citext, organism_db_name public.citext, owner_username public.citext, comment public.citext, propagation_mode smallint, special_processing public.citext, id integer, existing_job_count integer, message public.citext, returncode public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Evaluate predefined analysis rules for given list of datasets and return the list of jobs that would be created
**
**  Arguments:
**    _datasetList                      Comma-separated list of dataset names
**    _excludeDatasetsNotReleased       When true, excludes datasets with a rating of -5 (by default we exclude datasets with a rating < 2 and <> -10)
**    _createJobsForUnreviewedDatasets  When true, will create jobs for datasets with a rating of -10 using predefines with Trigger_Before_Disposition = 1
**    _analysisToolNameFilter           If not blank, only considers predefines that match the given tool name (can contain wildcards)
**
**  Auth:   grk
**  Date:   06/23/2005
**          03/28/2006 grk - Added protein collection fields
**          04/04/2006 grk - Increased sized of param file name
**          03/16/2007 mem - Replaced processor name with associated processor group (Ticket #388)
**          04/11/2008 mem - Now passing _raiseErrorMessages to EvaluatePredefinedAnalysisRules
**          07/22/2008 grk - Changed protein collection column names for final list report output
**          02/09/2011 mem - Now passing _excludeDatasetsNotReleased and _createJobsForUnreviewedDatasets to EvaluatePredefinedAnalysisRules
**          02/16/2011 mem - Added support for Propagation Mode (aka Export Mode)
**          02/20/2012 mem - Now using a temporary table to track the dataset names in _datasetList
**          02/22/2012 mem - Switched to using a table-variable for dataset names (instead of a physical temporary table)
**          05/03/2012 mem - Added support for the Special Processing field
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          06/30/2022 mem - Rename parameter file column
**          11/09/2022 mem - Ported to PostgreSQL
**          01/26/2023 mem - Include Predefine_ID in the query results
**          01/27/2023 mem - Show legacy FASTA file name after the protein collection info
**          02/08/2023 mem - Switch from PRN to username
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**                         - Fix bug that failed to pass _excludeDatasetsNotReleased and _createJobsForUnreviewedDatasets to predefined_analysis_jobs()
**
*****************************************************/
DECLARE
    _message text;
    _datasetName text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetList                     := Trim(Coalesce(_datasetList, ''));
    _excludeDatasetsNotReleased      := Coalesce(_excludeDatasetsNotReleased, true);
    _createJobsForUnreviewedDatasets := Coalesce(_createJobsForUnreviewedDatasets, true);
    _analysisToolNameFilter          := Trim(Coalesce(_analysisToolNameFilter, ''));

    ---------------------------------------------------
    -- Populate a temporary table with the dataset names to create jobs for
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetsToProcess
    (
        EntryID int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Dataset text
    );

    INSERT INTO Tmp_DatasetsToProcess (Dataset)
    SELECT Value
    FROM public.parse_delimited_list(_datasetList, ',')
    WHERE char_length(Value) > 0
    ORDER BY Value;

    If Not FOUND Then
        _message := 'Dataset list is empty; nothing to do';

        RAISE WARNING '%', _message;

        RETURN QUERY
        SELECT
            0,              -- Predefine_ID
            ''::citext,     -- Dataset
            0,              -- Priority
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
            ''::citext;     -- returncode

        DROP TABLE Tmp_DatasetsToProcess;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Temporary table to hold the list of jobs to create
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_PredefineJobsToCreate_MDS (
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
        id int NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        existing_job_count int,
        message citext,
        returncode citext
    );

    ---------------------------------------------------
    -- Process list into datasets and get set of generated jobs
    -- for each one into job holding table
    ---------------------------------------------------

    FOR _datasetName IN
        SELECT Src.Dataset
        FROM Tmp_DatasetsToProcess Src
        ORDER BY Src.EntryID
    LOOP
        ---------------------------------------------------
        -- Add jobs created for the dataset to the job holding table
        ---------------------------------------------------

        INSERT INTO Tmp_PredefineJobsToCreate_MDS (
            predefine_id, dataset, priority, analysis_tool_name, param_file_name, settings_file_name,
            organism_name, protein_collection_list, protein_options_list, organism_db_name,
            owner_username, comment, propagation_mode, special_processing,
            existing_job_count, message, returncode
        )
        SELECT Src.predefine_id,
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
               Src.existing_job_count,
               Src.message,
               Src.returncode
        FROM public.predefined_analysis_jobs(
                                _datasetName,
                                _raiseErrorMessages => true,
                                _excludeDatasetsNotReleased => _excludeDatasetsNotReleased,
                                _createJobsForUnreviewedDatasets => _createJobsForUnreviewedDatasets,
                                _analysisToolNameFilter => _analysisToolNameFilter) Src
        ORDER BY Src.ID;

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
        Src.existing_job_count,
        ''::citext AS message,
        ''::citext AS returncode
    FROM Tmp_PredefineJobsToCreate_MDS Src
    ORDER BY Src.dataset, Src.id;

    DROP TABLE Tmp_DatasetsToProcess;
    DROP TABLE Tmp_PredefineJobsToCreate_MDS;
END
$$;


ALTER FUNCTION public.predefined_analysis_jobs_mds(_datasetlist text, _excludedatasetsnotreleased boolean, _createjobsforunrevieweddatasets boolean, _analysistoolnamefilter text) OWNER TO d3l243;

--
-- Name: FUNCTION predefined_analysis_jobs_mds(_datasetlist text, _excludedatasetsnotreleased boolean, _createjobsforunrevieweddatasets boolean, _analysistoolnamefilter text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.predefined_analysis_jobs_mds(_datasetlist text, _excludedatasetsnotreleased boolean, _createjobsforunrevieweddatasets boolean, _analysistoolnamefilter text) IS 'EvaluatePredefinedAnalysisRulesMDS';

