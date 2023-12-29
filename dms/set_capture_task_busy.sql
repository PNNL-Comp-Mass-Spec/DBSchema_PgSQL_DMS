--
-- Name: set_capture_task_busy(text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.set_capture_task_busy(IN _datasetname text, IN _machinename text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update dataset state to 2 and update the prep server name
**
**  Arguments:
**    _datasetName      Dataset name
**    _machineName      Capture task machine; always '(broker)' (effective 2010-01-20)
**
**  Auth:   grk
**  Date:   12/15/2009
**          01/14/2010 grk - Removed path ID fields
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          06/16/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    _machineName := Trim(Coalesce(_machineName, ''));

    If _machineName = '' Then
        _machineName := 'na';
    End If;

    UPDATE t_dataset
    SET dataset_state_id = 2,
        ds_prep_server_name = _machineName
    WHERE dataset = _datasetName::citext;

    If Not FOUND Then
        _message := format('Dataset %s not found in t_dataset', Coalesce(_datasetName, '??'));
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Dataset: %s', _datasetName);
    CALL post_usage_log_entry ('set_capture_task_busy', _usageMessage);

END
$$;


ALTER PROCEDURE public.set_capture_task_busy(IN _datasetname text, IN _machinename text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_capture_task_busy(IN _datasetname text, IN _machinename text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.set_capture_task_busy(IN _datasetname text, IN _machinename text, INOUT _message text, INOUT _returncode text) IS 'SetCaptureTaskBusy';

