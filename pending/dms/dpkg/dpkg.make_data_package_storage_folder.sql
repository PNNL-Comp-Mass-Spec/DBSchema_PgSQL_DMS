--
CREATE OR REPLACE PROCEDURE dpkg.make_data_package_storage_folder
(
    _id int,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Requests creation of data storage folder for data package
**
**  Arguments:
**    _mode   or 'update'
**
**  Auth:   grk
**  Date:   06/03/2009
**          07/10/2009 dac - Incorporated tested changes from T3 version of SP
**          07/14/2009 mem - Now logging to T_Log_Entries
**          08/19/2009 grk - Added failover to backup broker
**          11/05/2009 grk - Modified to use external message sender
**          03/17/2011 mem - Now calling AddDataFolderCreateTask in the DMS_Pipeline database
**          04/07/2011 mem - Fixed bug constructing _pathFolder (year was in the wrong place)
**          07/30/2012 mem - Now updating _message prior to calling PostLogEntry
**          03/17/2016 mem - Remove call to CallSendMessage
**          07/05/2022 mem - Remove reference to obsolete column in view V_Data_Package_Folder_Creation_Parameters
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _pathLocalRoot text;
    _pathSharedRoot text;
    _pathFolder text;
    _sourceDB text := DB_Name();
    _queue text;
    _server1 text;
    _server2 text;
    _port int;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Lookup the parameters needed to call AddDataFolderCreateTask
    ---------------------------------------------------

    SELECT Local
           share,
           team || '\' || [year] || '\' || folder
    INTO _pathLocalRoot, _pathSharedRoot, _pathFolder
    FROM V_Data_Package_Folder_Creation_Parameters
    WHERE ID = _id;

    CALL sw.add_data_folder_create_task (
                    _pathLocalRoot => _pathLocalRoot,
                    _pathSharedRoot => _pathSharedRoot,
                    _folderPath => _pathFolder,
                    _sourceDB => _sourceDB,
                    _sourceTable => 'dpkg.t_data_package',
                    _sourceID => _id,
                    _sourceIDFieldName = 'data_pkg_id',
                    _command => 'add');

    ---------------------------------------------------
    -- Call call_send_message, which will use xp_cmdshell to run C:\DMS_Programs\DBMessageSender\DBMessageSender.exe
    -- We stopped doing this in February 2016 because login DMSWebUser no longer has EXECUTE privileges on xp_cmdshell
    ---------------------------------------------------
    --
    /*
    CALL call_send_message _id, _mode, _message output

    If Coalesce(_message, '') = '' Then
        _message := format('Called SendMessage for Data Package ID %s: %s', _packageID, _pathFolder);
    End If;

    CALL public.post_log_entry ('Normal', _message, 'Make_Data_Package_Storage_Folder', 'dpkg', _callingUser => _CallingUser);
    */

/*
** The following was the original method for doing this, using .NET function SendMessage
**

    SELECT
        _creationParams = '<params>' ||
        '<package>' || _id::text || '</package>' ||
        '<local>' || path_local_root || '</local>' ||
        '<share>' || path_shared_root || '</share>' ||
        '<year>' || path_year || '</year>' ||
        '<team>' || path_team || '</team>' ||
        '<folder>' || package_directory || '</folder>' ||
        '<cmd>' || _mode || '</cmd>' ||
        '</params>'
    FROM
      dpkg.t_data_package
      INNER JOIN dpkg.t_data_package_storage
        ON dpkg.t_data_package.storage_path_id = dpkg.t_data_package_storage.data_pkg_id
    WHERE  (dpkg.t_data_package.data_pkg_id = _id)

    ---------------------------------------------------

    SELECT '/queue/' + value FROM dpkg.t_properties WHERE property = 'MessageQueue' INTO _queue
    SELECT value FROM dpkg.t_properties WHERE property = 'MessagePort' INTO _port
    SELECT value FROM dpkg.t_properties WHERE property = 'MessageBroker1' INTO _server1
    SELECT value FROM dpkg.t_properties WHERE property = 'MessageBroker2' INTO _server2

    _msg := '';
    CALL send_message _creationParams, _queue, _server1, _port, _msg output
    if _myError <> 0 Then
        _msg := '';
        CALL send_message _creationParams, _queue, _server2, _port, _msg output
    End If;
    if _myError <> 0 Then
        _message := _msg;
    End If;

    _message := format('Calling SendMessage: %s', _creationParams);
    CALL public.post_log_entry ('Normal', _message, 'Make_Data_Package_Storage_Folder', 'dpkg', _callingUser => _CallingUser);
*/

END
$$;

COMMENT ON PROCEDURE dpkg.make_data_package_storage_folder IS 'MakeDataPackageStorageFolder';
