--
-- Name: delete_dataset(text, boolean, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_dataset(IN _datasetname text, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete the given dataset from the dataset table and all referencing tables
**
**  Arguments:
**    _datasetName      Dataset name
**    _infoOnly         When true, preview deletes
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**    _showDebug        When true, show debug messages
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
**          09/15/2023 mem - Ported to PostgreSQL
**          09/29/2023 mem - Store the dataset's storage_path_id in _datasetDirectoryPath if V_Dataset_Folder_Paths does not have the dataset
**          12/28/2023 mem - Use a variable for target type when calling alter_event_log_entry_user()
**          02/04/2024 mem - Add parameter _showDebug
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetID int;
    _state int;
    _datasetDirectoryPath text := null;
    _requestID int := null;
    _stateID int := 0;
    _targetType int;
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
    _callingUser := Trim(Coalesce(_callingUser, ''));
    _infoOnly    := Coalesce(_infoOnly, true);
    _showDebug   := Coalesce(_showDebug, false);

    If _showDebug Then
        RAISE INFO '';
    End If;

    If _datasetName = '' Then
        _message := '_datasetName parameter is blank; nothing to delete';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get the datasetID and current state
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Resolve dataset name to ID: %', _datasetName;
    End If;

    SELECT dataset_state_id,
           dataset_id
    INTO _state, _datasetID
    FROM t_dataset
    WHERE dataset = _datasetName::citext;

    If Not FOUND Then
        _message := format('Dataset does not exist: %s', _datasetName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get the dataset directory path
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Determine the dataset directory path';
    End If;

    SELECT Dataset_Folder_Path
    INTO _datasetDirectoryPath
    FROM V_Dataset_Folder_Paths
    WHERE Dataset_ID = _datasetID;

    If Not FOUND THEN
        SELECT format('Dataset folder in %s (storage path ID %s; dataset not found in V_Dataset_Folder_Paths)',
                      SPath.vol_name_client || SPath.storage_path,
                      DS.storage_path_id)
        INTO _datasetDirectoryPath
        FROM t_dataset DS INNER JOIN
             t_storage_path SPath
               ON DS.storage_path_id = SPath.storage_path_id
        WHERE DS.dataset = _datasetName::citext;
    End If;

    If Exists (SELECT dataset_id FROM t_analysis_job WHERE dataset_id = _datasetID) Then
        _message := 'Cannot delete a dataset with existing analysis jobs';
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If _infoOnly Then

        If _showDebug Then
            RAISE INFO 'Preview items to delete';
        End If;

        -- Populate a temporary table with the list of items to delete or update

        CREATE TEMP TABLE T_Tmp_Target_Items (
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
               _datasetDirectoryPath,
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

    If _showDebug Then
        RAISE INFO 'Delete dataset ID % from t_dataset_archive', _datasetID;
    End If;

    DELETE FROM t_dataset_archive
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete any auxiliary info associated with dataset
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Call delete_aux_info';
    End If;

    CALL public.delete_aux_info (
                    'Dataset',
                    _datasetName,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode);    -- Output

    If _returnCode <> '' Then
        If _showDebug Then
            RAISE INFO 'Return code from delete_aux_info is %; show message %', _returnCode, _message;
        End If;

        _message := format('Delete auxiliary information was unsuccessful for dataset: %s', _message);
        RAISE EXCEPTION '%', _message;

        RETURN;
    Else
        If _showDebug Then
            RAISE INFO 'Successful call to delete_aux_info';
        End If;
    End If;

    ---------------------------------------------------
    -- Restore any consumed requested runs
    ---------------------------------------------------

    SELECT request_id
    INTO _requestID
    FROM t_requested_run
    WHERE dataset_id = _datasetID;

    If _showDebug Then
        If _requestID Is Null Then
            RAISE INFO 'Call unconsume_scheduled_run (though the dataset does not have a requested run)';
        Else
            RAISE INFO 'Call unconsume_scheduled_run for requested run %', _requestID;
        End If;
    End If;

    CALL public.unconsume_scheduled_run (
                    _datasetName,
                    _retainHistory => false,
                    _message       => _message,         -- Output
                    _returnCode    => _returnCode,      -- Output
                    _callingUser   => _callingUser,
                    _showDebug     => _showDebug);

    If _returnCode <> '' Then
        If _showDebug Then
            RAISE INFO 'Return code from unconsume_scheduled_run is %; show message %', _returnCode, _message;
        End If;

        _message := format('Unconsume operation was unsuccessful for dataset: %s', _message);
        RAISE EXCEPTION '%', _message;

        RETURN;
    Else
        If _showDebug Then
            RAISE INFO 'Successful call to unconsume_scheduled_run';
        End If;
    End If;

    _message := '';

    If Not _requestID Is Null Then

        If _showDebug Then
            RAISE INFO 'Show the updated requested run';
        End If;

        RAISE INFO '';

        _formatSpecifier := '%-135s %-10s %-40s %-10s %-30s %-20s %-9s %-8s %-25s';

        _infoHead := format(_formatSpecifier,
                            'Message',
                            'Request_ID',
                            'Request_Name',
                            'State_Name',
                            'Comment',
                            'Created',
                            'Exp_ID',
                            'Batch_ID',
                            'Instrument_Group'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------------------------------------------------------------------------------------------------------------------------------------',
                                     '----------',
                                     '----------------------------------------',
                                     '----------',
                                     '------------------------------',
                                     '--------------------',
                                     '---------',
                                     '--------',
                                     '-------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'Request updated; verify this action, especially if the deleted dataset was replaced with an identical, renamed dataset' AS message,
                   Request_ID,
                   Request_Name,
                   State_Name,
                   Comment,
                   Created,
                   Exp_ID,
                   Batch_ID,
                   Instrument_Group
            FROM t_requested_run
            WHERE request_id = _requestID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Message,
                                _previewData.Request_ID,
                                _previewData.Request_Name,
                                _previewData.State_Name,
                                _previewData.Comment,
                                _previewData.Created,
                                _previewData.Exp_ID,
                                _previewData.Batch_ID,
                                _previewData.Instrument_Group
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    ---------------------------------------------------
    -- Delete any entries in t_dataset_info
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Delete dataset ID % from t_dataset_info', _datasetID;
    End If;

    DELETE FROM t_dataset_info
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete any entries in t_dataset_qc
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Delete dataset ID % from t_dataset_qc', _datasetID;
    End If;

    DELETE FROM t_dataset_qc
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete any entries in t_dataset_scan_types
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Delete dataset ID % from t_dataset_scan_types', _datasetID;
    End If;

    DELETE FROM t_dataset_scan_types
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Mark entries in t_dataset_files as Deleted
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Delete dataset ID % from t_dataset_files', _datasetID;
    End If;

    UPDATE t_dataset_files
    SET deleted = true
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete rows in t_cached_dataset_instruments
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Delete dataset ID % from t_cached_dataset_instruments', _datasetID;
    End If;

    DELETE from t_cached_dataset_instruments
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Delete any failed jobs in cap.t_tasks
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Delete dataset ID % from cap.t_tasks (if state is 5)', _datasetID;
    End If;

    DELETE FROM cap.t_tasks
    WHERE Dataset_ID = _datasetID AND State = 5;

    ---------------------------------------------------
    -- Update log entries in cap.t_log_entries
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Update cap.t_log_entries to change "Error" entries to "ErrorAutoFixed" for dataset %', _datasetName;
    End If;

    UPDATE cap.t_log_entries
    SET type = 'ErrorAutoFixed'
    WHERE type = 'Error' AND
          message ILike '%' || _datasetName || '%';

    ---------------------------------------------------
    -- Remove jobs from cap.t_tasks
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Delete dataset ID % from cap.t_tasks if the capture task job is also in cap.t_tasks_History', _datasetID;
    End If;

    DELETE FROM cap.t_tasks Tasks
    WHERE Tasks.Dataset_ID = _datasetID AND
          Tasks.Job IN (SELECT History.job
                        FROM cap.t_tasks_History History
                        WHERE History.dataset_id = _datasetID);

    ---------------------------------------------------
    -- Delete entry from dataset table
    ---------------------------------------------------

    If _showDebug Then
        RAISE INFO 'Delete dataset ID % from t_dataset', _datasetID;
    End If;

    DELETE FROM t_dataset
    WHERE dataset_id = _datasetID;

    -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
    If _callingUser <> '' Then

        If _showDebug Then
            RAISE INFO 'Call alter_event_log_entry_user for dataset ID % and state %', _datasetID, _stateID;
        End If;

        _targetType := 4;
        CALL public.alter_event_log_entry_user ('public', _targetType, _datasetID, _stateID, _callingUser, _message => _alterEnteredByMessage);
    End If;

    RAISE INFO 'Deleted dataset ID %', _datasetID;

    RAISE INFO 'ToDo: delete %', _datasetDirectoryPath;

END
$$;


ALTER PROCEDURE public.delete_dataset(IN _datasetname text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_dataset(IN _datasetname text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_dataset(IN _datasetname text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean) IS 'DeleteDataset';

