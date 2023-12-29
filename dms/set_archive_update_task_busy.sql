--
-- Name: set_archive_update_task_busy(text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.set_archive_update_task_busy(IN _datasetname text, IN _storageservername text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Set archive update state to 3 (Update In Progress) in t_dataset_archive for the given dataset
**
**  Auth:   grk
**  Date:   12/15/2009
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          06/16/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
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

    UPDATE t_dataset_archive
    SET archive_update_state_id = 3,
        update_processor = _storageServerName
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        _message := format('Dataset ID %s not found in t_dataset_archive (for dataset %s)', _datasetID, Coalesce(_datasetName , '??'));
        _returnCode := 'U5221';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Dataset: %s', _datasetName);
    CALL post_usage_log_entry ('set_archive_update_task_busy', _usageMessage);

END
$$;


ALTER PROCEDURE public.set_archive_update_task_busy(IN _datasetname text, IN _storageservername text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_archive_update_task_busy(IN _datasetname text, IN _storageservername text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.set_archive_update_task_busy(IN _datasetname text, IN _storageservername text, INOUT _message text, INOUT _returncode text) IS 'SetArchiveUpdateTaskBusy';

