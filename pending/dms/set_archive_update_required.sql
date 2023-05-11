--
CREATE OR REPLACE PROCEDURE public.set_archive_update_required
(
    _datasetName text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Sets archive status of dataset to update required
**
**  Auth:   grk
**  Date:   12/3/2002
**          03/06/2007 grk - add changes for deep purge (ticket #403)
**          03/07/2007 dac - fixed incorrect check for 'in progress' update states (ticket #408)
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          07/09/2022 mem - Tabs to spaces
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
    _updateState int;
    _archiveState int;
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

    SELECT
        _datasetID = Dataset_ID,
        _updateState = Update_State,
        _archiveState = Archive_State
    FROM V_Dataset_Archive_Ex
    WHERE Dataset = _datasetName;

    If Not FOUND Then
        _returnCode := 'U5220';
        _message := format('Dataset "%s" not found in V_DatasetArchive_Ex', _datasetName;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Check dataset archive update state for 'in progress'
    ---------------------------------------------------
    If not _updateState in (1, 2, 4, 5) Then
        _returnCode := 'U5250';
        _message := 'Archive update state for dataset "' || _datasetName || '" is not correct';
        RETURN;
    End If;

    ---------------------------------------------------
    -- If archive state is 'purged', set it to 'complete'
    -- to allow for re-purging
    ---------------------------------------------------
    If _archiveState = 4 Then
        _archiveState := 3;
    End If;

    ---------------------------------------------------
    -- Update dataset archive state
    ---------------------------------------------------

    UPDATE t_dataset_archive
    SET archive_update_state_id = 2, archive_state_id = _archiveState
    WHERE (dataset_id = _datasetID);

    If Not FOUND Then
        _returnCode := 'U5299';
        _message := format('Dataset ID %s not found in t_dataset_archive', _datasetID;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := 'Dataset: ' || _datasetName;
    Call post_usage_log_entry ('Set_Archive_Update_Required', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.set_archive_update_required IS 'SetArchiveUpdateRequired';
