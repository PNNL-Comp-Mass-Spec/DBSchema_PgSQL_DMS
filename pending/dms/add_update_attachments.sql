--
CREATE OR REPLACE PROCEDURE public.add_update_attachments
(
    INOUT _id int,
    _attachmentType text,
    _attachmentName text,
    _attachmentDescription text,
    _ownerUsername text,
    _active text,
    _contents text,
    _fileName text,
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
**      Adds new or edits existing Attachments
**
**  Arguments:
**    _mode   'add' or 'update'
**
**  Auth:   grk
**  Date:   03/24/2009
**  Date:   07/22/2010 grk -- allowed update mode
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _tmp int;
BEGIN
  _message := '';

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

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        -- Cannot update a non-existent entry
        --
        SELECT attachment_id
        INTO _tmp
        FROM  t_attachments
        WHERE attachment_id = _id;

        If Not FOUND Then
            _message := 'No entry could be found in database for update';
            RAISE EXCEPTION '%', _message;
        End If;

    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    If _mode = 'add' Then

        INSERT INTO t_attachments (
            attachment_type,
            attachment_name,
            attachment_description,
            owner_username,
            active,
            contents,
            file_name
        ) VALUES (
            _attachmentType,
            _attachmentName,
            _attachmentDescription,
            _ownerUsername,
            _active,
            _contents,
            _fileName
        )
        RETURNING attachment_id
        INTO _id;

    End If; -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If _mode = 'update' Then
        --

        UPDATE t_attachments
        SET attachment_type = _attachmentType,
            attachment_name = _attachmentName,
            attachment_description = _attachmentDescription,
            owner_username = _ownerUsername,
            active = _active,
            contents = _contents,
            file_name = _fileName
        WHERE attachment_id = _id;

    End If; -- update mode

END
$$;

COMMENT ON PROCEDURE public.add_update_attachments IS 'AddUpdateAttachments';
