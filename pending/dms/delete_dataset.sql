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
**          03/01/2004 grk - Added unconsume scheduled run
**          04/07/2006 grk - Got rid of dataset list stuff
**          04/07/2006 grk - Got rid of CDBurn stuff
**          05/01/2007 grk - Modified to call modified Unconsume_scheduled_run (Ticket #446)
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          05/08/2009 mem - Now checking T_Dataset_Info
**          12/13/2011 mem - Now passing _callingUser to Unconsume_scheduled_run
**                         - Now checking T_Dataset_QC and T_Dataset_ScanTypes
**          02/19/2013 mem - No longer allowing deletion if analysis jobs exist
**          02/21/2013 mem - Updated call to Unconsume_scheduled_run to refer to _retainHistory by name
**          05/08/2013 mem - No longer passing _wellplateName and _wellNumber to Unconsume_scheduled_run
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
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetID int;
    _state int;
    _datasetDirectoryPath text := Null;
    _requestID int := Null;
    _stateID int := 0;
    _alterEnteredByMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _datasetName := Trim(Coalesce(_datasetName, ''));

    If _datasetName = '' Then
        _message := '_datasetName parameter is blank; nothing to delete';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get the datasetID and current state
    ---------------------------------------------------

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

        -- Populate a temporary table with the list of items to delete or update

        CREATE TEMPORARY TABLE T_Tmp_Target_Items (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Action text,
            Item_Type text,
            Item_ID text,
            Item_Name text,
            Comment text
        );

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted' AS Action,
               'Dataset Archive Info',
               DS.Dataset_ID,
               DS.dataset,
               format('Archive state %s, last affected %s', DA.archive_state_id,
                 PUBLIC.timestamp_text(DA.archive_state_last_affected))
        FROM t_dataset_archive DA
             INNER JOIN t_dataset DS
               ON DA.dataset_id = DS.dataset_id
        WHERE DA.dataset_id = _datasetID;

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT CASE WHEN request_name::citext Like 'AutoReq%'
                    THEN 'To be deleted'
                    ELSE 'To be marked active'
               END AS Action,
               'Requested Run',
               Request_ID,
               Request_Name,
               format('Experiment ID: %s, Instrument Group: %s', Exp_ID, Instrument_Group)
        FROM t_requested_run
        WHERE dataset_id = _datasetID;

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted' AS Action,
               'Dataset Info',
               Dataset_ID,
               format('Scan types: %s', scan_types),
               format('Last affected: %s', last_affected)
        FROM t_dataset_info
        WHERE dataset_id = _datasetID;

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted' AS ACTION,
               'Dataset QC',
               Dataset_ID,
               format('Quameter job %s, SMAQC job %s', Coalesce(quameter_job, 0), Coalesce(smaqc_job, 0)),
               ''
        FROM t_dataset_qc
        WHERE dataset_id = _datasetID;

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted' AS Action,
               'Dataset Scan Type',
               Entry_ID,
               Scan_Type,
               Scan_Filter
        FROM t_dataset_scan_types
        WHERE dataset_id = _datasetID;

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be flagged As deleted' AS Action,
               'Dataset File',
               dataset_file_id,
               file_path,
               format('Hash: %s', file_hash)
        FROM t_dataset_files
        WHERE dataset_id = _datasetID;

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted' AS Action,
               'Failed Capture Task',
               job,
               script,
               format('State: %s, Imported: %s', State, public.timestamp_text(imported))
        FROM cap.t_tasks
        WHERE dataset_id = _datasetID And
              State = 5;

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted' AS Action,
               'Dataset Info XML',
               dataset_id,
               Substring(ds_info_xml::text, 1, 500),
               format('Cache date: %s', public.timestamp_text(cache_date))
        FROM cap.t_dataset_info_xml
        WHERE dataset_id = _datasetID;

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted' AS Action,
               'Capture task',
               Jobs.job,
               Jobs.script,
               format('State: %s, Imported: %s', Jobs.State, public.timestamp_text(Jobs.imported))
        FROM cap.t_tasks Jobs
             INNER JOIN cap.t_tasks_History History
               ON Jobs.Job = History.Job
        WHERE Jobs.Dataset_ID = _datasetID AND
              NOT History.Job IS NULL;

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be deleted' AS Action,
               'Dataset',
               Dataset_ID,
               Dataset,
               format('Experiment ID: %s, Instrument ID: %s, Created: %s', Exp_ID, Instrument_ID, public.timestamp_text(Created))
        FROM t_dataset
        WHERE dataset_id = _datasetID;

        INSERT INTO T_Tmp_Target_Items (Action, Item_Type, Item_ID, Item_Name, Comment)
        SELECT 'To be manually deleted' As Action,
               'Dataset Directory',
               _datasetID,
               '\\proto-5\share\year\dataset', -- _datasetDirectoryPath,
               '';

        -- Show the contents of T_Tmp_Target_Items

        RAISE INFO '';

        _formatSpecifier := '%-25s %-20s %-8s %-80s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Action',
                            'Item_Type',
                            'Item_ID',
                            'Item_Name',
                            'Comment'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-------------------------',
                                     '--------------------',
                                     '--------',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Action, Item_Type, Item_ID, Item_Name, Comment
            FROM T_Tmp_Target_Items
            ORDER BY Entry_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Action,
                                _previewData.Item_Type,
                                _previewData.Item_ID,
                                _previewData.Item_Name,
                                _previewData.Comment
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE T_Tmp_Target_Items;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete any entries for the dataset from the archive table
    ---------------------------------------------------

    DELETE FROM t_dataset_archive
    WHERE dataset_id = _datasetID

    ---------------------------------------------------
    -- Delete any auxiliary info associated with dataset
    ---------------------------------------------------

    CALL delete_aux_info 'Dataset', _datasetName, _message => _message, _returnCode => _returnCode);

    If _returnCode <> '' Then
        _message := format('Delete auxiliary information was unsuccessful for dataset: %s', _message);
        RAISE EXCEPTION '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Restore any consumed requested runs
    ---------------------------------------------------

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

    DELETE FROM t_dataset_info
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete any entries in t_dataset_qc
    ---------------------------------------------------

    DELETE FROM t_dataset_qc
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete any entries in t_dataset_scan_types
    ---------------------------------------------------

    DELETE FROM t_dataset_scan_types
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Mark entries in t_dataset_files as Deleted
    ---------------------------------------------------

    UPDATE t_dataset_files
    SET deleted = 1
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete rows in t_cached_dataset_instruments
    ---------------------------------------------------

    DELETE from t_cached_dataset_instruments
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete any failed jobs in cap.t_tasks
    ---------------------------------------------------

    DELETE FROM cap.t_tasks
    WHERE Dataset_ID = _datasetID AND State = 5;

    ---------------------------------------------------
    -- Update log entries in cap.t_log_entries
    ---------------------------------------------------

    UPDATE cap.t_log_entries
    SET type = 'ErrorAutoFixed'
    WHERE type = 'error' AND
          message LIKE '%' || _datasetName || '%';

    ---------------------------------------------------
    -- Remove jobs from cap.t_tasks
    ---------------------------------------------------

    DELETE cap.t_tasks Tasks
    FROM cap.t_tasks_History History
    WHERE Jobs.Dataset_ID = _datasetID AND
          Jobs.Job = History.Job;

    ---------------------------------------------------
    -- Delete entry from dataset table
    ---------------------------------------------------

    DELETE FROM t_dataset
    WHERE dataset_id = _datasetID;

    -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
    If char_length(_callingUser) > 0 Then
        CALL public.alter_event_log_entry_user ('public', 4, _datasetID, _stateID, _callingUser, _message => _alterEnteredByMessage);
    End If;

    RAISE INFO 'Deleted dataset ID %', _datasetID;

    RAISE INFO 'ToDo: delete %', _datasetDirectoryPath;

END
$$;

COMMENT ON PROCEDURE public.delete_dataset IS 'DeleteDataset';
