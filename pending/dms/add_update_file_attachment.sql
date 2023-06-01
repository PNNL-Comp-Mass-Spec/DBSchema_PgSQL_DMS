--
CREATE OR REPLACE PROCEDURE public.add_update_file_attachment
(
    _id int,
    _fileName text,
    _description text,
    _entityType text,
    _entityID text,
    _fileSizeBytes text,
    _archiveFolderPath text,
    _fileMimeType text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing item in T_File_Attachment
**
**      Note that _entityType will be the same as the
**      DMS website page family name of the item the file attachment
**      is attached to; see the upload method in File_attachment.php
**
**  Arguments:
**    _entityType          Page family name: campaign, experiment, sample_prep_request, lc_cart_configuration, etc.
**    _entityID            Must be data type varchar since Experiment, Campaign, Cell Culture, and Material Container file attachments are tracked via Experiment Name, Campaign Name, etc.
**    _fileSizeBytes       This file size is actually in KB
**    _archiveFolderPath   This path is constructed when File_attachment.php or Experiment_File_attachment.php calls function GetFileAttachmentPath in this database
**    _mode                'add' or 'update'
**
**  Auth:   grk
**  Date:   03/30/2011
**          03/30/2011 grk - Don't allow duplicate entries
**          12/16/2011 mem - Convert null descriptions to empty strings
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/11/2021 mem - Store integers in Entity_ID_Value
**          03/27/2022 mem - Assure that Active is 1 when updating an existing file attachment
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _attachmentID int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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

    BEGIN

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then

            SELECT attachment_id
            INTO _attachmentID
            FROM  t_file_attachment
            WHERE (attachment_id = _id)

            -- Cannot update a non-existent entry
            If Not FOUND Then
                RAISE EXCEPTION 'No entry could be found in database for update';
            End If;
        End If;

        If _mode = 'add' Then
            -- When a file attachment is deleted the database record is not deleted
            -- Instead, Active is set to 0
            -- If a user re-attaches a 'deleted' file to an entity, we need to use 'update' for the _mode

            SELECT attachment_id
            INTO _attachmentID
            FROM t_file_attachment
            WHERE entity_type = _entityType AND
                  entity_id = _entityID AND
                  file_name = _fileName;

            If FOUND Then
                _mode := 'update';
                _id := _attachmentID;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------
        --
        If _mode = 'add' Then
            INSERT INTO t_file_attachment (
                file_name,
                description,
                entity_type,
                entity_id,
                entity_id_value,
                owner_username,
                file_size_bytes,
                archive_folder_path,
                file_mime_type,
                active)
            VALUES (
                _fileName,
                Coalesce(_description, ''),
                _entityType,
                _entityID,
                Case When _entityType::citext In ('campaign', 'cell_culture', 'biomaterial', 'experiment', 'material_container')
                     Then Null
                     Else public.try_cast(_entityID, null::int)
                End
                _callingUser,
                _fileSizeBytes,
                _archiveFolderPath,
                _fileMimeType,
                1
            )
            RETURNING attachment_id
            INTO _id;

        End -- add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If _mode = 'update' Then

            UPDATE t_file_attachment
            Set description = Coalesce(_description, ''),
                entity_type = _entityType,
                entity_id = _entityID,
                entity_id_value =
                    Case When _entityType::citext In ('campaign', 'cell_culture', 'biomaterial', 'experiment', 'material_container')
                         Then Null
                         Else public.try_cast(_entityID, null::int)
                    End
                File_Size_Bytes = _fileSizeBytes,
                Last_Affected = CURRENT_TIMESTAMP,
                Archive_Folder_Path = _archiveFolderPath,
                File_Mime_Type = _fileMimeType,
                Active = 1
            WHERE ID = _id;

        End If; -- update mode

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('%s; Job %s', _exceptionMessage, _job);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;
END
$$;

COMMENT ON PROCEDURE public.add_update_file_attachment IS 'AddUpdateFileAttachment';
