--
-- Name: set_archive_update_task_complete(text, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.set_archive_update_task_complete(IN _datasetname text, IN _completioncode integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Set archive update state to 4 (Update Complete) in t_dataset_archive if _completionCode is 0
**      Otherwise, set archive update state to 4 (Update Failed)
**
**  Arguments:
**    _datasetName          Dataset name
**    _completionCode       Completion code: 0=success, 1=failure, >1 means no intermediate files
**
**  Auth:   grk
**  Date:   12/03/2002
**          12/06/2002 dac - Corrected state values used in update state test, update complete output
**          11/30/2007 dac - Removed unused processor name parameter
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          04/16/2014 mem - Now changing archive state to 3 if it is 14
**          07/09/2022 mem - Tabs to spaces
**          06/16/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _datasetID int;
    _updateState int;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Resolve dataset name to ID and archive state
    ---------------------------------------------------

    SELECT dataset_id
    INTO _datasetID
    FROM t_dataset
    WHERE dataset = _datasetName::citext;

    If Not FOUND Then
        _message := format('Dataset %s not found in t_dataset', Coalesce(_datasetName, '??'));
        _returnCode := 'U5220';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    SELECT archive_update_state_id
    INTO _updateState
    FROM t_dataset_archive
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        _message := format('Dataset ID %s not found in t_dataset_archive (for dataset %s)', _datasetID, Coalesce(_datasetName, '??'));
        _returnCode := 'U5221';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Check dataset archive state for 'in progress'
    ---------------------------------------------------

    If _updateState <> 3 Then
        _returnCode := 'U5250';
        _message := format('Archive update state is not correct for dataset %s (expecting 3 but actually %s)', _datasetName, _updateState);
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
                               END,
            last_update = CURRENT_TIMESTAMP
        WHERE dataset_id = _datasetID;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

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
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

    End If;

    If _updateCount <> 1 Then
        _returnCode := 'U5299';
        _message := format('Update operation failed (_updateCount is %s instead of 1)', _updateCount);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Dataset: %s', _datasetName);
    CALL post_usage_log_entry ('set_archive_update_task_complete', _usageMessage);

END
$$;


ALTER PROCEDURE public.set_archive_update_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_archive_update_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.set_archive_update_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text) IS 'SetArchiveUpdateTaskComplete';

