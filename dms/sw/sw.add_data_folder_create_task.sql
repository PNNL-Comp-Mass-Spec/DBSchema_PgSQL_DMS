--
-- Name: add_data_folder_create_task(text, text, text, text, integer, text, text, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.add_data_folder_create_task(IN _pathlocalroot text, IN _pathsharedroot text, IN _folderpath text, IN _sourcetable text, IN _sourceid integer, IN _sourceidfieldname text, IN _command text DEFAULT 'add'::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add a new entry to T_Data_Folder_Create_Queue
**
**      The Package Folder Create Manager (aka PkgFolderCreateManager) examines this table to look for folders that need to be created
**
**  Arguments:
**    _pathLocalRoot        Required, for example: F:\DataPkgs
**    _pathSharedRoot       Required, for example: \\protoapps\DataPkgs\
**    _folderPath           Required, for example: Public\2011\264_PNWRCE_Dengue_iTRAQ
**    _sourceTable          Optional, for example: T_Data_Package
**    _sourceID             Optional, for example: 264
**    _sourceIDFieldName    Optional, for example: ID
**    _command              Optional, for example: add
**    _infoOnly             When true, preview the info that would be added to T_Data_Folder_Create_Queue
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   03/17/2011 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/04/2023 mem - Ported to PostgreSQL
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    If _infoOnly Then
        _message := format('Add row to t_data_folder_create_queue for %s = %s in table %s, command ''%s'', folder path ''%s'', local root ''%s'', share root ''%s''',
                           _sourceIDFieldName, _sourceID, _sourceTable, _command,
                           _folderPath, _pathLocalRoot, _sourceIDFieldName);

    Else
        INSERT INTO sw.t_data_folder_create_queue
        (
            state,
            source_db,
            source_table,
            source_id,
            source_id_field_name,
            path_local_root,
            path_shared_root,
            path_folder,
            command
        )
        VALUES ( 1,      -- State
                 'DMS',
                 _sourceTable,
                 _sourceID,
                 _sourceIDFieldName,
                 _pathLocalRoot,
                 _pathSharedRoot,
                 _folderPath,
                 _command
               );
    End If;

END
$$;


ALTER PROCEDURE sw.add_data_folder_create_task(IN _pathlocalroot text, IN _pathsharedroot text, IN _folderpath text, IN _sourcetable text, IN _sourceid integer, IN _sourceidfieldname text, IN _command text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_data_folder_create_task(IN _pathlocalroot text, IN _pathsharedroot text, IN _folderpath text, IN _sourcetable text, IN _sourceid integer, IN _sourceidfieldname text, IN _command text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.add_data_folder_create_task(IN _pathlocalroot text, IN _pathsharedroot text, IN _folderpath text, IN _sourcetable text, IN _sourceid integer, IN _sourceidfieldname text, IN _command text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'AddDataFolderCreateTask';

