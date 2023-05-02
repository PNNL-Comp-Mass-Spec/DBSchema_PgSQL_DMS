--
CREATE OR REPLACE PROCEDURE sw.add_data_folder_create_task
(
    _pathLocalRoot text,
    _pathSharedRoot text,
    _folderPath text,
    _sourceDB text,
    _sourceTable text,
    _sourceID int,
    _sourceIDFieldName text,
    _command text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a new entry to T_Data_Folder_Create_Queue
**      The Package Folder Create Manager (aka PkgFolderCreateManager)
**      examines this table to look for folders that need to be created
**
**  Arguments:
**    _pathLocalRoot       Required, for example: F:\DataPkgs
**    _pathSharedRoot      Required, for example: \\protoapps\DataPkgs\
**    _folderPath          Required, for example: Public\2011\264_PNWRCE_Dengue_iTRAQ
**    _sourceDB            Optional, for example: DMS_Data_Package
**    _sourceTable         Optional, for example: T_Data_Package
**    _sourceID            Optional, for example: 264
**    _sourceIDFieldName   Optional, for example: ID
**    _command             Optional, for example: add
**
**  Auth:   mem
**  Date:   03/17/2011 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
BEGIN
    _message := '';
    _returnCode:= '';

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

    If _infoOnly Then
        SELECT
            1 AS State,
            _sourceDB as SourceDB,
            _sourceTable as SourceTable,
            _sourceID as SourceID,
            _sourceIDFieldName as SourceIDFieldName,
            _pathLocalRoot as PathLocalRoot,
            _pathSharedRoot as PathSharedRoot,
            _folderPath as FolderPath,
            _command as Command
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
        SELECT
            1 AS State,
            _sourceDB,
            _sourceTable,
            _sourceID,
            _sourceIDFieldName,
            _pathLocalRoot,
            _pathSharedRoot,
            _folderPath,
            _command
    End If;

END
$$;

COMMENT ON PROCEDURE sw.add_data_folder_create_task IS 'AddDataFolderCreateTask';
