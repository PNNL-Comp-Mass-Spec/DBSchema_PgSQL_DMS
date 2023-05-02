--
CREATE OR REPLACE PROCEDURE public.set_archive_update_task_busy
(
    _datasetName text,
    _storageServerName text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
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
**        09/02/2011 mem - Now calling PostUsageLogEntry
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode:= '';

    UPDATE t_dataset_archive
    SET archive_update_state_id = 3,
        update_processor = _storageServerName
    FROM t_dataset_archive
         INNER JOIN t_dataset
           ON t_dataset.dataset_id = t_dataset_archive.dataset_id
    WHERE t_dataset.dataset = _datasetName;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := 'Dataset: ' || _datasetName;
    Call post_usage_log_entry ('SetArchiveUpdateTaskBusy', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.set_archive_update_task_busy IS 'SetArchiveUpdateTaskBusy';
