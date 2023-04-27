--
CREATE OR REPLACE PROCEDURE public.set_capture_task_busy
(
    _datasetName text,
    _machineName text,
    INOUT _message text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Sets appropriate dataset state to busy
**
**  Auth:   grk
**  Date:   12/15/2009
**          01/14/2010 grk - removed path ID fields
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _usageMessage text;
BEGIN
    _message := '';

    UPDATE t_dataset
    SET dataset_state_id = 2,
        ds_prep_server_name = _machineName
    WHERE dataset = _datasetName;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := 'Dataset: ' || _datasetName;
    Call post_usage_log_entry ('SetCaptureTaskBusy', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.set_capture_task_busy IS 'SetCaptureTaskBusy';
