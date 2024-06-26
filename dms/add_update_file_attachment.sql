--
-- Name: add_update_file_attachment(integer, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_file_attachment(IN _id integer, IN _filename text, IN _description text, IN _entitytype text, IN _entityid text, IN _filesizekb text, IN _archivefolderpath text, IN _filemimetype text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing file attachment
**
**      Note that _entityType will be the same as the DMS website page family name of the item
**      that the file attachment is attached to; see the upload method in File_attachment.php
**
**  Arguments:
**    _id                   File attachment ID in t_file_attachment
**    _fileName             File name
**    _description          Description
**    _entityType           Page family name: 'campaign', 'experiment', 'sample_prep_request', 'lc_cart_configuration', etc.
**    _entityID             Data type must be text since Experiment, Campaign, Biomaterial, and Material Container file attachments are tracked via Experiment Name, Campaign Name, etc.
**    _fileSizeKB           File size, in kilobytes
**    _archiveFolderPath    This path is constructed when File_attachment.php or Experiment_File_attachment.php calls function Get_File_Attachment_Path() in this database
**    _fileMimeType         MIME type
**    _mode                 Mode: 'add' or 'update'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
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
**          01/09/2024 mem - Rename file size parameter to @fileSizeKB
**                         - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _attachmentID int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _fileName          := Trim(Coalesce(_fileName, ''));
        _description       := Trim(Coalesce(_description, ''));
        _entityType        := Trim(Coalesce(_entityType, ''));
        _entityID          := Trim(Coalesce(_entityID, ''));
        _fileSizeKB        := Trim(Coalesce(_fileSizeKB, ''));
        _archiveFolderPath := Trim(Coalesce(_archiveFolderPath, ''));
        _fileMimeType      := Trim(Coalesce(_fileMimeType, ''));
        _callingUser       := Trim(Coalesce(_callingUser, ''));
        _mode              := Trim(Lower(Coalesce(_mode, '')));

        If Not _mode IN ('add', 'update') Then
            RAISE EXCEPTION 'Mode should be add or update, not "%"', _mode;
        End If;

        If _fileName = '' Then
            RAISE EXCEPTION 'Cannot %: filename must be specified', _mode;
        End If;

        If _entityType = '' Then
            RAISE EXCEPTION 'Cannot %: entity type must be specified', _mode;
        End If;

        If _entityID = '' Then
            RAISE EXCEPTION 'Cannot %: entity ID must be specified', _mode;
        End If;

        If _fileSizeKB = '' Then
            RAISE EXCEPTION 'Cannot %: file size must be specified', _mode;
        End If;

        If _callingUser = '' Then
            _callingUser = SESSION_USER;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            If _id Is Null Then
                _logErrors := false;
                RAISE EXCEPTION 'Cannot update: attachment ID cannot be null';
            End If;

            SELECT attachment_id
            INTO _attachmentID
            FROM t_file_attachment
            WHERE attachment_id = _id;

            -- Cannot update a non-existent entry
            If Not FOUND Then
                RAISE EXCEPTION 'Cannot update: attachment ID % does not exist', _id;
            End If;
        End If;

        If _mode = 'add' Then
            -- When a file attachment is deleted, the database record is not deleted
            -- Instead, Active is set to 0
            -- If a user re-attaches a 'deleted' file to an entity, we need to use 'update' for _mode

            SELECT attachment_id
            INTO _attachmentID
            FROM t_file_attachment
            WHERE entity_type = _entityType::citext AND
                  entity_id   = _entityID::citext AND
                  file_name   = _fileName::citext;

            If FOUND Then
                _mode := 'update';
                _id := _attachmentID;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            INSERT INTO t_file_attachment (
                file_name,
                description,
                entity_type,
                entity_id,
                entity_id_value,
                owner_username,
                file_size_kb,
                archive_folder_path,
                file_mime_type,
                active
            ) VALUES (
                _fileName,
                _description,
                _entityType,
                _entityID,
                CASE WHEN _entityType::citext In ('campaign', 'cell_culture', 'biomaterial', 'experiment', 'material_container')
                     THEN Null
                     ELSE public.try_cast(_entityID, null::int)
                END,
                _callingUser,
                _fileSizeKB,
                _archiveFolderPath,
                _fileMimeType,
                1
            )
            RETURNING attachment_id
            INTO _id;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_file_attachment
            SET description         = _description,
                entity_type         = _entityType,
                entity_id           = _entityID,
                entity_id_value     = CASE WHEN _entityType::citext In ('campaign', 'cell_culture', 'biomaterial', 'experiment', 'material_container')
                                           THEN Null
                                           ELSE public.try_cast(_entityID, null::int)
                                      END,
                owner_username      = _callingUser,
                file_size_kb        = _fileSizeKB,
                Last_Affected       = CURRENT_TIMESTAMP,
                Archive_Folder_Path = _archiveFolderPath,
                File_Mime_Type      = _fileMimeType,
                Active              = 1
            WHERE attachment_id = _id;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _id Is Null Then
            _logMessage := _exceptionMessage;
        Else
            _logMessage := format('%s; Attachment ID %s', _exceptionMessage, _id);
        End If;

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => _logErrors);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;
END
$$;


ALTER PROCEDURE public.add_update_file_attachment(IN _id integer, IN _filename text, IN _description text, IN _entitytype text, IN _entityid text, IN _filesizekb text, IN _archivefolderpath text, IN _filemimetype text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_file_attachment(IN _id integer, IN _filename text, IN _description text, IN _entitytype text, IN _entityid text, IN _filesizekb text, IN _archivefolderpath text, IN _filemimetype text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_file_attachment(IN _id integer, IN _filename text, IN _description text, IN _entitytype text, IN _entityid text, IN _filesizekb text, IN _archivefolderpath text, IN _filemimetype text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateFileAttachment';

