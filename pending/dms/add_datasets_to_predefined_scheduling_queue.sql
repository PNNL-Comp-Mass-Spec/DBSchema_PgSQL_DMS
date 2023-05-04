--
CREATE OR REPLACE PROCEDURE public.add_datasets_to_predefined_scheduling_queue
(
    _datasetIDs text = '',
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds datasets to T_Predefined_Analysis_Scheduling_Queue
**      so that they can be checked against the predefined analysis job rules
**
**      Useful for processing a set of datasets after creating a new predefine
**
**  Arguments:
**    _datasetIDs   List of dataset IDs (comma, tab, or newline separated)
**
**  Auth:   mem
**  Date:   03/31/2016 mem - Initial Version
**          12/15/2023 mem - Ported to PostgreSQL
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetIDs := Coalesce(_datasetIDs, '');
    _infoOnly := Coalesce(_infoOnly, false);
    _callingUser := Coalesce(_callingUser, '');

    If _callingUser = '' Then
        _callingUser := session_user;
    End If;

    ---------------------------------------------------
    -- Create a temporary table to keep track of the datasets
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetsToProcess (
        Dataset_ID int NOT NULL,
        IsValid boolean NOT NULL,
        AlreadyWaiting boolean NOT NULL
    );

    INSERT INTO Tmp_DatasetsToProcess (Dataset_ID, IsValid, AlreadyWaiting)
    SELECT DISTINCT Value, false, false
    FROM public.parse_delimited_integer_list(_datasetIDs, ',');

    ---------------------------------------------------
    -- Look for invalid dataset IDs
    ---------------------------------------------------

    UPDATE Tmp_DatasetsToProcess
    SET IsValid = true
    FROM t_dataset DS
    WHERE Tmp_DatasetsToProcess.dataset_id = DS.dataset_id;

    If Exists (SELECT * FROM Tmp_DatasetsToProcess WHERE Not IsValid) Then
        RAISE WARNING 'One or more dataset IDs was not present in t_dataset';
    End If;

    ---------------------------------------------------
    -- Look for Datasets already present in t_predefined_analysis_scheduling_queue
    -- with state 'New'
    ---------------------------------------------------

    UPDATE Tmp_DatasetsToProcess
    SET AlreadyWaiting = true
    FROM t_predefined_analysis_scheduling_queue SchedQueue
    WHERE Tmp_DatasetsToProcess.dataset_id = SchedQueue.dataset_id AND
          SchedQueue.state = 'New';

    If FOUND Then
        RAISE INFO 'One or more dataset IDs is already in t_predefined_analysis_scheduling_queue with state "New"';
    End If;

    If _infoOnly Then

        -- ToDo: Preview results
        SELECT Source.dataset_id,
               CASE
               WHEN AlreadyWaiting > 0 THEN 'Already in t_predefined_analysis_scheduling_queue with state "New"'
               ELSE CASE
                    WHEN IsValid = 0 THEN 'Unknown dataset_id'
                    ELSE ''
                    End If;
               END AS Error_Message,
               _callingUser AS CallingUser,
               '' AS AnalysisToolNameFilter,
               'Yes' AS ExcludeDatasetsNotReleased,
               'Yes' AS PreventDuplicateJobs,
               'New' AS State
        FROM Tmp_DatasetsToProcess Source
             LEFT OUTER JOIN t_dataset DS
               ON Source.dataset_id = DS.dataset_id;

    Else

        INSERT INTO t_predefined_analysis_scheduling_queue( dataset_id,
                                                            calling_user,
                                                            analysis_tool_name_filter,
                                                            exclude_datasets_not_released,
                                                            prevent_duplicate_jobs,
                                                            state,
                                                            message )
        SELECT dataset_id,
               _callingUser,
               '' AS AnalysisToolNameFilter,
               'Yes' AS ExcludeDatasetsNotReleased,
               'Yes' AS PreventDuplicateJobs,
               'New' AS State,
               '' AS Message
        FROM Tmp_DatasetsToProcess
        WHERE IsValid And Not AlreadyWaiting;
        --
        GET DIAGNOSTICS _jobCountToProcess = ROW_COUNT;

        RAISE INFO 'Added % datasets to t_predefined_analysis_scheduling_queue', _jobCountToProcess;

    End If;

    DROP TABLE Tmp_DatasetsToProcess;
END
$$;

COMMENT ON PROCEDURE public.add_datasets_to_predefined_scheduling_queue IS 'AddDatasetsToPredefinedSchedulingQueue';
