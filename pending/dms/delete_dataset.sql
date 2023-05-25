--
CREATE OR REPLACE PROCEDURE public.delete_dataset
(
    _datasetName text,
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes given dataset from the dataset table and all referencing tables
**
**  Auth:   grk
**  Date:   01/26/2001
**          03/01/2004 grk - added unconsume scheduled run
**          04/07/2006 grk - got rid of dataset list stuff
**          04/07/2006 grk - Got rid of CDBurn stuff
**          05/01/2007 grk - Modified to call modified UnconsumeScheduledRun (Ticket #446)
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          05/08/2009 mem - Now checking T_Dataset_Info
**          12/13/2011 mem - Now passing _callingUser to UnconsumeScheduledRun
**                         - Now checking T_Dataset_QC and T_Dataset_ScanTypes
**          02/19/2013 mem - No longer allowing deletion if analysis jobs exist
**          02/21/2013 mem - Updated call to UnconsumeScheduledRun to refer to _retainHistory by name
**          05/08/2013 mem - No longer passing _wellplateName and _wellNumber to UnconsumeScheduledRun
**          08/31/2016 mem - Delete failed capture jobs for the dataset
**          10/27/2016 mem - Update T_Log_Entries in DMS_Capture
**          01/23/2017 mem - Delete jobs from cap.t_tasks
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/08/2018 mem - Update T_Dataset_Files
**          09/27/2018 mem - Added parameter _infoOnly
**                         - Now showing the unconsumed requested run
**          09/28/2018 mem - Flag AutoReq requested runs as 'To be deleted' instead of 'To be marked active'
**          11/16/2018 mem - Delete dataset file info from cap.T_Dataset_Info_XML
**                           Change the default for _infoOnly to true
**                           Rename the first parameter
**          04/17/2019 mem - Delete rows in T_Cached_Dataset_Instruments
**          11/02/2021 mem - Show the full path to the dataset directory at the console
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetID int;
    _state int;
    _datasetDirectoryPath text := Null;
    _requestID int := Null;
    _stateID int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _datasetName := Coalesce(_datasetName, '');

    If _datasetName = '' Then
        _message := '_datasetName parameter is blank; nothing to delete';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get the datasetID and current state
    ---------------------------------------------------
    --
    _datasetID := 0;
    --
    SELECT dataset_state_id,
        dataset_id
    INTO _state, _datasetID
    FROM t_dataset
    WHERE dataset = _datasetName

    If Not FOUND Then
        _message := format('Dataset does not exist: %s', _datasetName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get the dataset directory path
    ---------------------------------------------------
    --

    SELECT Dataset_Folder_Path
    INTO _datasetDirectoryPath
    FROM V_Dataset_Folder_Paths
    WHERE Dataset_ID = _datasetID;

    If Exists (SELECT * FROM t_analysis_job WHERE dataset_id = _datasetID) Then
        _message := 'Cannot delete a dataset with existing analysis jobs';
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        SELECT 'To be deleted' AS Action, *
        FROM t_dataset_archive
        WHERE dataset_id = _datasetID

        If Exists (SELECT * FROM t_requested_run WHERE dataset_id = _datasetID) Then
            SELECT CASE WHEN request_name::citext Like 'AutoReq%'
                        THEN 'To be deleted'
                        ELSE 'To be marked active'
                   END AS Action, *
            FROM t_requested_run
            WHERE dataset_id = _datasetID
        End If;

        SELECT 'To be deleted' AS Action, *
        FROM t_dataset_info
        WHERE dataset_id = _datasetID

        SELECT 'To be deleted' AS Action, *
        FROM t_dataset_qc
        WHERE dataset_id = _datasetID

        SELECT 'To be deleted' AS Action, *
        FROM t_dataset_scan_types
        WHERE dataset_id = _datasetID

        SELECT 'To be flagged as deleted' AS Action, *
        FROM t_dataset_files
        WHERE dataset_id = _datasetID

        If Exists (SELECT * FROM cap.t_tasks WHERE Dataset_ID = _datasetID AND State = 5) Then
            SELECT 'To be deleted' AS Action, *
            FROM cap.t_tasks
            WHERE Dataset_ID = _datasetID And State = 5
        End If;

        If Exists (SELECT * FROM cap.T_Dataset_Info_XML WHERE Dataset_ID = _datasetID) Then
            SELECT 'To be deleted' AS Action, *
            FROM cap.T_Dataset_Info_XML
            WHERE Dataset_ID = _datasetID
        End If;

        SELECT 'To be deleted' AS Action, Jobs.*
        FROM cap.t_tasks Jobs
             INNER JOIN cap.t_tasks_History History
               ON Jobs.Job = History.Job
        WHERE Jobs.Dataset_ID = _datasetID AND
              NOT History.Job IS NULL

        SELECT 'To be deleted' AS Action, *
        FROM t_dataset
        WHERE dataset_id = _datasetID

        RAISE INFO 'Directory to remove: %', _datasetDirectoryPath;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete any entries for the dataset from the archive table
    ---------------------------------------------------
    --
    DELETE FROM t_dataset_archive
    WHERE dataset_id = _datasetID

    ---------------------------------------------------
    -- Delete any auxiliary info associated with dataset
    ---------------------------------------------------
    --
    CALL delete_aux_info 'Dataset', _datasetName, _message => _message, _returnCode => _returnCode);

    If _returnCode <> '' Then
        _message := format('Delete auxiliary information was unsuccessful for dataset: %s', _message);
        RAISE EXCEPTION '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Restore any consumed requested runs
    ---------------------------------------------------
    --

    SELECT request_id
    INTO _requestID
    FROM t_requested_run
    WHERE dataset_id = _datasetID;

    CALL unconsume_scheduled_run (_datasetName, _retainHistory => false, _message => _message, _returnCode => _returnCode, _callingUser => _callingUser);

    If _returnCode <> '' Then
        _message := format('Unconsume operation was unsuccessful for dataset: %s', _message);
        RAISE EXCEPTION '%', _message;

        RETURN;
    End If;

    If Not _requestID Is Null Then
        SELECT 'Request updated; verify this action, especially if the deleted dataset was replaced with an identical, renamed dataset' AS Comment, *
        FROM t_requested_run
        WHERE request_id = _requestID
    End If;

    ---------------------------------------------------
    -- Delete any entries in t_dataset_info
    ---------------------------------------------------
    --
    DELETE FROM t_dataset_info
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete any entries in t_dataset_qc
    ---------------------------------------------------
    --
    DELETE FROM t_dataset_qc
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete any entries in t_dataset_scan_types
    ---------------------------------------------------
    --
    DELETE FROM t_dataset_scan_types
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Mark entries in t_dataset_files as Deleted
    ---------------------------------------------------
    --
    UPDATE t_dataset_files
    SET deleted = 1
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete rows in t_cached_dataset_instruments
    ---------------------------------------------------
    --
    DELETE from t_cached_dataset_instruments
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete any failed jobs in the DMS_Capture database
    ---------------------------------------------------
    --
    DELETE FROM cap.t_tasks
    WHERE Dataset_ID = _datasetID AND State = 5;

    ---------------------------------------------------
    -- Update log entries in the DMS_Capture database
    ---------------------------------------------------
    --
    UPDATE cap.t_log_entries
    SET type = 'ErrorAutoFixed'
    WHERE type = 'error' AND
          message LIKE '%' || _datasetName || '%';

    ---------------------------------------------------
    -- Remove jobs from cap.t_tasks
    ---------------------------------------------------
    --
    DELETE cap.t_tasks Tasks
    FROM cap.t_tasks_History History
    WHERE Jobs.Dataset_ID = _datasetID AND
          Jobs.Job = History.Job;

    ---------------------------------------------------
    -- Delete entry from dataset table
    ---------------------------------------------------
    --
    DELETE FROM t_dataset
    WHERE dataset_id = _datasetID;

    -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
    If char_length(_callingUser) > 0 Then
        CALL alter_event_log_entry_user (4, _datasetID, _stateID, _callingUser);
    End If;

    RAISE INFO 'Deleted dataset ID %', _datasetID;

    RAISE INFO 'ToDo: delete %', _datasetDirectoryPath;

END
$$;

COMMENT ON PROCEDURE public.delete_dataset IS 'DeleteDataset';
