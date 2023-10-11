--
-- Name: make_osm_package_storage_folder(integer, boolean, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.make_osm_package_storage_folder(IN _id integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Requests creation of data storage folder for OSM Package
**
**  Arguments:
**    _id           OSM Package ID
**    _infoOnly     When true, preview the info that would be added to T_Data_Folder_Create_Queue
**
**  Auth:   grk
**  Date:   08/21/2013
**          05/27/2016 mem - Remove call to CallSendMessage
**          06/04/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _pathSharedRoot text := '';
    _pathFolder text := '';
BEGIN
    _message := '';
    _returnCode := '';

    If _id Is Null Then
        _message := 'OSM Package ID is null, cannot call add_data_folder_create_task';
        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the parameters needed to call add_data_folder_create_task
    ---------------------------------------------------

    SELECT Path_Shared_Root, Path_Folder
    INTO _pathSharedRoot, _pathFolder
    FROM V_OSM_Package_Paths
    WHERE ID = _id;

    If Not FOUND Then
        _message := format('OSM Package ID %s not found in V_OSM_Package_Paths', _id);
        _returnCode := 'U5201';
        RETURN;
    End If;

    CALL sw.add_data_folder_create_task (
                    _pathLocalRoot     => '',
                    _pathSharedRoot    => _pathSharedRoot,
                    _folderPath        => _pathFolder,
                    _sourceTable       => 'dpkg.t_osm_package',
                    _sourceID          => _id,
                    _sourceIDFieldName => 'osm_pkg_id',
                    _command           => 'add',
                    _infoOnly          => _infoOnly,
                    _message           => _message,         -- Output
                    _returnCode        => _returnCode);     -- Output
END
$$;


ALTER PROCEDURE dpkg.make_osm_package_storage_folder(IN _id integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE make_osm_package_storage_folder(IN _id integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.make_osm_package_storage_folder(IN _id integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'MakeOSMPackageStorageFolder';

