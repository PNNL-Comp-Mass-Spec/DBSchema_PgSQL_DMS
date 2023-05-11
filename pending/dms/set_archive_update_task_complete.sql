--
CREATE OR REPLACE PROCEDURE public.set_archive_update_task_complete
(
    _datasetName text,
    _completionCode int default 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Sets status of task to successful completion or to failed
**      (according to value of input argument)
**
**  Arguments:
**    _datasetName                dataset for which archive task is being completed
**    _completionCode            0->success, 1->failure, anything else ->no intermediate files
**
**  Auth:   grk
**  Date:   12/03/2002
**          12/06/2002 dac - Corrected state values used in update state test, update complete output
**          11/30/2007 dac - Removed unused processor name parameter
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          04/16/2014 mem - Now changing archive state to 3 if it is 14
**          07/09/2022 mem - Tabs to spaces
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _datasetID int;
    _updateState int;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Resolve dataset name to ID and archive state
    ---------------------------------------------------
    --
    _datasetID := 0;
    _updateState := 0;
    --
    SELECT
        _datasetID = Dataset_ID,
        _updateState = Update_State
    FROM V_Dataset_Archive_Ex
    WHERE Dataset = _datasetName;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If Not FOUND Then
        _returnCode := 'U5220';
        _message := format('Dataset "%s" not found in V_DatasetArchive_Ex', _datasetName);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Check dataset archive state for 'in progress'
    ---------------------------------------------------
    If _updateState <> 3 Then
        _returnCode := 'U5250';
        _message := 'Archive update state for dataset "' || _datasetName || '" is not correct';
        RETURN;
    End If;

    _completionCode := Coalesce(_completionCode, 0);

    ---------------------------------------------------
    -- Update dataset archive state
    ---------------------------------------------------

    If _completionCode = 0 Then
        -- Success
        UPDATE t_dataset_archive
        SET archive_update_state_id = 4,
            archive_state_id = CASE
                              WHEN archive_state_id = 14 THEN 3
                              ELSE archive_state_id
                          End If;,
            last_update = CURRENT_TIMESTAMP
        WHERE dataset_id = _datasetID;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    Else
        -- Error
        UPDATE t_dataset_archive
        SET archive_update_state_id = 5,
            archive_state_id = CASE
                              WHEN archive_state_id = 14 THEN 3
                              ELSE archive_state_id
                          END
        WHERE dataset_id = _datasetID;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    End If;

    If _myRowCount <> 1 Then
        _returnCode := 'U5299';
        _message := 'Update operation failed';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := 'Dataset: ' || _datasetName;
    Call post_usage_log_entry ('Set_Archive_Update_Task_Complete', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.set_archive_update_task_complete IS 'SetArchiveUpdateTaskComplete';
