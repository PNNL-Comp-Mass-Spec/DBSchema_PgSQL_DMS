--
-- Name: add_datasets_to_predefined_scheduling_queue(text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_datasets_to_predefined_scheduling_queue(IN _datasetids text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add datasets to public.t_predefined_analysis_scheduling_queue so that they can be checked against the predefined analysis job rules
**
**      Useful for processing a set of datasets after creating a new predefine
**
**  Arguments:
**    _datasetIDs       List of dataset IDs (comma, tab, or newline separated)
**    _infoOnly         When true, preview rows that would be added
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user username
**
**  Auth:   mem
**  Date:   03/31/2016 mem - Initial Version
**          09/05/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
    _insertCount int;

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

    _datasetIDs  := Coalesce(_datasetIDs, '');
    _infoOnly    := Coalesce(_infoOnly, false);
    _callingUser := Trim(Coalesce(_callingUser, ''));

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
    FROM public.parse_delimited_integer_list(_datasetIDs);

    ---------------------------------------------------
    -- Look for invalid dataset IDs
    ---------------------------------------------------

    UPDATE Tmp_DatasetsToProcess
    SET IsValid = true
    FROM t_dataset DS
    WHERE Tmp_DatasetsToProcess.dataset_id = DS.dataset_id;

    If Exists (SELECT Dataset_ID FROM Tmp_DatasetsToProcess WHERE Not IsValid) Then
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

        RAISE INFO '';

        _formatSpecifier := '%-10s %-66s %-12s %-25s %-23s %-22s %-5s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'Error_Message',
                            'Calling_User',
                            'Analysis_Tool_Name_Filter',
                            'Exclude_DS_Not_Released',
                            'Prevent_Duplicate_Jobs',
                            'State'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '------------------------------------------------------------------',
                                     '------------',
                                     '-------------------------',
                                     '-----------------------',
                                     '----------------------',
                                     '-----'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Source.dataset_id AS DatasetID,
                   CASE WHEN AlreadyWaiting
                        THEN 'Already in t_predefined_analysis_scheduling_queue with state "New"'
                   ELSE
                        CASE WHEN Not IsValid
                             THEN 'Unknown dataset_id'
                             ELSE ''
                        END
                   END AS ErrorMessage,
                   _callingUser AS CallingUser,
                   '' AS AnalysisToolNameFilter,
                   'Yes' AS ExcludeDatasetsNotReleased,
                   'Yes' AS PreventDuplicateJobs,
                   'New' AS State
            FROM Tmp_DatasetsToProcess Source
                 LEFT OUTER JOIN t_dataset DS
                   ON Source.dataset_id = DS.dataset_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.DatasetID,
                                _previewData.ErrorMessage,
                                _previewData.CallingUser,
                                _previewData.AnalysisToolNameFilter,
                                _previewData.ExcludeDatasetsNotReleased,
                                _previewData.PreventDuplicateJobs,
                                _previewData.State
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_DatasetsToProcess;
        RETURN;
    End If;

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
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    RAISE INFO 'Added % % to t_predefined_analysis_scheduling_queue', _insertCount, public.check_plural(_insertCount, 'dataset', 'datasets');

    DROP TABLE Tmp_DatasetsToProcess;
END
$$;


ALTER PROCEDURE public.add_datasets_to_predefined_scheduling_queue(IN _datasetids text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_datasets_to_predefined_scheduling_queue(IN _datasetids text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_datasets_to_predefined_scheduling_queue(IN _datasetids text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddDatasetsToPredefinedSchedulingQueue';

