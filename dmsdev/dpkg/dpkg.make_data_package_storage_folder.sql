--
-- Name: make_data_package_storage_folder(integer, boolean, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.make_data_package_storage_folder(IN _id integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Request creation of data storage folder for data package
**
**  Arguments:
**    _id           Data package ID
**    _infoOnly     When true, preview the info that would be added to T_Data_Folder_Create_Queue
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   06/03/2009
**          07/10/2009 dac - Incorporated tested changes from T3 version of SP
**          07/14/2009 mem - Now logging to T_Log_Entries
**          08/19/2009 grk - Added failover to backup broker
**          11/05/2009 grk - Modified to use external message sender
**          03/17/2011 mem - Now calling Add_Data_Folder_Create_Task in the DMS_Pipeline database
**          04/07/2011 mem - Fixed bug constructing _pathFolder (year was in the wrong place)
**          07/30/2012 mem - Now updating _message prior to calling post_log_entry
**          03/17/2016 mem - Remove call to CallSendMessage
**          07/05/2022 mem - Remove reference to obsolete column in view V_Data_Package_Folder_Creation_Parameters
**          06/04/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _pathLocalRoot text;
    _pathSharedRoot text;
    _pathFolder text;
BEGIN
    _message := '';
    _returnCode := '';

    If _id Is Null Then
        _message := 'Data Package ID is null, cannot call add_data_folder_create_task';
        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the parameters needed to call add_data_folder_create_task
    ---------------------------------------------------

    SELECT Local,
           Share,
           format('%s\%s\%s', Team, Year, Folder)
    INTO _pathLocalRoot, _pathSharedRoot, _pathFolder
    FROM V_Data_Package_Folder_Creation_Parameters
    WHERE ID = _id;

    If Not FOUND Then
        _message := format('Data Package ID %s not found in V_Data_Package_Folder_Creation_Parameters', _id);
        _returnCode := 'U5202';
        RETURN;
    End If;

    CALL sw.add_data_folder_create_task (
                    _pathLocalRoot     => _pathLocalRoot,
                    _pathSharedRoot    => _pathSharedRoot,
                    _folderPath        => _pathFolder,
                    _sourceTable       => 'dpkg.t_data_package',
                    _sourceID          => _id,
                    _sourceIDFieldName => 'data_pkg_id',
                    _command           => 'add',
                    _infoOnly          => _infoOnly,
                    _message           => _message,         -- Output
                    _returnCode        => _returnCode);     -- Output
END
$$;


ALTER PROCEDURE dpkg.make_data_package_storage_folder(IN _id integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE make_data_package_storage_folder(IN _id integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.make_data_package_storage_folder(IN _id integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'MakeDataPackageStorageFolder';

