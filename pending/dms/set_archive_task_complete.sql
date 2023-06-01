--
CREATE OR REPLACE PROCEDURE public.set_archive_task_complete
(
    _datasetName text,
    _completionCode int = 0,
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
**    _datasetName          Dataset for archive task
**    _completionCode       0->success, 1->failure, anything else ->no intermediate files
**
**  Auth:   grk
**  Date:   09/26/2002
**          06/21/2005 grk - Added handling for 'requires_preparation'
**          11/27/2007 dac - Removed _processorname param, which is no longer required
**          03/23/2009 mem - Now updating AS_Last_Successful_Archive when the archive state is 3=Complete (Ticket #726)
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          12/17/2009 grk - Added special success code '100' for use by capture broker
**          07/09/2022 mem - Tabs to spaces
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
    _archiveState int;
    _doPrep int;
    _tmpState int;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Resolve dataset name to ID and archive state
    ---------------------------------------------------
    --
    _datasetID := 0;
    _archiveState := 0;

    SELECT Dataset_ID,
           Archive_State,
           Requires_Prep
    INTO _datasetID, _archiveState, _doPrep
    FROM V_Dataset_Archive_Ex
    WHERE Dataset = _datasetName;

    If Not FOUND Then
        _returnCode := 'U5220';
        _message := format('Dataset "%s" not found in V_DatasetArchive_Ex', _datasetName;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Check dataset archive state for 'in progress'
    ---------------------------------------------------

    If _archiveState <> 2 Then
        _returnCode := 'U5250';
        _message := format('Archive state for dataset "%s" is not correct (expecting 2 but actually %s)', _datasetName, _archiveState);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update dataset archive state
    ---------------------------------------------------

    If _completionCode = 0 OR _completionCode = 100 Then
        -- Task completed successfully

        -- Decide what state is next
        --
        If _completionCode = 100 Then
            _tmpState := 3;
        ElsIf _doPrep = 0 Then
            _tmpState := 3;
        Else
            _tmpState := 11;
        End If;

        -- Update the state
        --
        UPDATE t_dataset_archive
        SET archive_state_id = _tmpState,
            archive_update_state_id = 4,
            last_update = CURRENT_TIMESTAMP,
            last_verify = CURRENT_TIMESTAMP,
            last_successful_archive =
                    CASE WHEN _tmpState = 3
                    THEN CURRENT_TIMESTAMP
                    ELSE AS_Last_Successful_Archive
                    End If;
        WHERE dataset_id = _datasetID;

    Else
        -- Task completed unsuccessfully

        UPDATE t_dataset_archive
        SET    archive_state_id = 6
        WHERE dataset_id = _datasetID;

    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Dataset: %s', _datasetName);
    CALL post_usage_log_entry ('Set_Archive_Task_Complete', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.set_archive_task_complete IS 'SetArchiveTaskComplete';
