--
CREATE OR REPLACE PROCEDURE public.update_myemsl_state
(
    _datasetID int,
    _analysisJobResultsFolder text,
    _myEMSLState int
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the MyEMSL State for a given dataset and/or its analysis jobs
**
**  Auth:   mem
**  Date:   09/11/2013 mem - Initial Version
**          10/18/2013 mem - No excluding jobs that are in-progress when _analysisJobResultsFolder is empty
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    If Coalesce(_analysisJobResultsFolder, '') = '' Then
        -- Update the dataset and all existing jobs
        --
        UPDATE t_dataset_archive
        SET myemsl_state = _myEMSLState
        WHERE dataset_id = _datasetID AND
                myemsl_state < _myEMSLState

        UPDATE t_analysis_job
        SET myemsl_state = _myEMSLState
        WHERE dataset_id = _datasetID AND
                myemsl_state < _myEMSLState AND
                job_state_id IN (4, 7, 14)

    Else
        -- Update the job that corresponds to _analysisJobResultsFolder
        --
        UPDATE t_analysis_job
        SET myemsl_state = _myEMSLState
        WHERE dataset_id = _datasetID AND
                results_folder_name = _analysisJobResultsFolder AND
                myemsl_state < _myEMSLState

    End If;

END
$$;

COMMENT ON PROCEDURE public.update_myemsl_state IS 'UpdateMyEMSLState';
