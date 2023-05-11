--
CREATE OR REPLACE PROCEDURE public.set_archive_task_busy
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
**        01/14/2010 grk - removed path ID fields
**        09/02/2011 mem - Now calling PostUsageLogEntry
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode:= '';

    UPDATE t_dataset_archive
    SET archive_state_id = 2,
        archive_processor = _storageServerName
    FROM t_dataset_archive
         INNER JOIN t_dataset
           ON t_dataset.dataset_id = t_dataset_archive.dataset_id
    WHERE t_dataset.dataset = _datasetName;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := 'Dataset: ' || _datasetName;
    Call post_usage_log_entry ('Set_Archive_Task_Busy', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.set_archive_task_busy IS 'SetArchiveTaskBusy';
