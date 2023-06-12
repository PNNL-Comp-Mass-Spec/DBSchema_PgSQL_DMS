--
-- Name: update_myemsl_state(integer, text, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_myemsl_state(IN _datasetid integer, IN _analysisjobresultsfolder text, IN _myemslstate integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the MyEMSL state for a given dataset and/or its analysis jobs
**
**      If _analysisJobResultsFolder is null or an empty string, updates t_dataset_archive and all rows in t_analysis_job for this dataset
**      Otherwise, only updates the job in t_analysis_job that matches the dataset and the job results folder
**
**  Arguments:
**    _datasetID                    Dataset ID
**    _analysisJobResultsFolder     Analysis job results folder
**    _myEMSLState int              New MyEMSL state
**
**  Auth:   mem
**  Date:   09/11/2013 mem - Initial Version
**          10/18/2013 mem - No excluding jobs that are in-progress when _analysisJobResultsFolder is empty
**          06/11/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    If _datasetID Is Null Then
        RAISE WARNING 'Argument _datasetID is null; unable to continue';
        RETURN;
    End If;

    If _myEMSLState Is Null Then
        RAISE WARNING 'Argument _myEMSLState is null; unable to continue';
        RETURN;
    End If;

    If Trim(Coalesce(_analysisJobResultsFolder, '')) = '' Then
        -- Update the dataset and all existing jobs
        --
        UPDATE t_dataset_archive
        SET myemsl_state = _myEMSLState
        WHERE dataset_id = _datasetID AND
              myemsl_state < _myEMSLState;

        UPDATE t_analysis_job
        SET myemsl_state = _myEMSLState
        WHERE dataset_id = _datasetID AND
                myemsl_state < _myEMSLState AND
                job_state_id IN (4, 7, 14);

    Else
        -- Update the job that corresponds to _analysisJobResultsFolder
        --
        UPDATE t_analysis_job
        SET myemsl_state = _myEMSLState
        WHERE dataset_id = _datasetID AND
              results_folder_name = _analysisJobResultsFolder AND
              myemsl_state < _myEMSLState;

    End If;

END
$$;


ALTER PROCEDURE public.update_myemsl_state(IN _datasetid integer, IN _analysisjobresultsfolder text, IN _myemslstate integer) OWNER TO d3l243;

--
-- Name: PROCEDURE update_myemsl_state(IN _datasetid integer, IN _analysisjobresultsfolder text, IN _myemslstate integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_myemsl_state(IN _datasetid integer, IN _analysisjobresultsfolder text, IN _myemslstate integer) IS 'UpdateMyEMSLState';

