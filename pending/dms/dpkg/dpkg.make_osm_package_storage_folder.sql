--
CREATE OR REPLACE PROCEDURE dpkg.make_osm_package_storage_folder
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
**  Desc:   Requests creation of data storage folder for OSM Package
**
**  Arguments:
**    _mode   or 'update'
**
**  Auth:   grk
**  Date:   08/21/2013
**          05/27/2016 mem - Remove call to CallSendMessage
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _packageID int;
    _pathLocalRoot text := '';
    _pathSharedRoot text := '';
    _pathFolder text := '';
    _sourceDB text := DB_Name();
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Lookup the parameters needed to call AddDataFolderCreateTask
    ---------------------------------------------------

    SELECT
        _packageID = ID,
        _pathSharedRoot  = Path_Shared_Root ,
        _pathFolder = Path_Folder
    FROM    V_OSM_Package_Paths
    WHERE ID = _id

    Call s_add_data_folder_create_task
                    _pathLocalRoot = _pathLocalRoot,
                    _pathSharedRoot = _pathSharedRoot,
                    _folderPath = _pathFolder,
                    _sourceDB = _sourceDB,
                    _sourceTable = 'dpkg.t_osm_package',
                    _sourceID = _packageID,
                    _sourceIDFieldName = 'osm_pkg_id',
                    _command = 'add'

    ---------------------------------------------------
    -- EXECUTE CallSendMessage, which will use xp_cmdshell to run C:\DMS_Programs\DBMessageSender\DBMessageSender.exe
    -- We stopped doing this in May 2016 because login DMSWebUser no longer has EXECUTE privileges on xp_cmdshell
    ---------------------------------------------------
    --
    /*
    Call call_send_message _id, _mode, _message output

    If Coalesce(_message, '') = '' Then
        _message := 'Called SendMessage for OSM Package ID ' || _packageID::text || ': ' || _pathFolder;
    End If;

    Call post_log_entry ('Normal', _message, 'Make_OSM_Package_Storage_Folder', 'dpkg', _callingUser => _CallingUser)
    */

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

    return _myError

END
$$;

COMMENT ON PROCEDURE dpkg.make_osm_package_storage_folder IS 'MakeOSMPackageStorageFolder';
