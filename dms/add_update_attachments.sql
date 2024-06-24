--
-- Name: add_update_attachments(integer, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_attachments(INOUT _id integer, IN _attachmenttype text, IN _attachmentname text, IN _attachmentdescription text, IN _ownerusername text, IN _active text, IN _contents text, IN _filename text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing MRM transition list attachment
**
**      This procedure is obsolete; MRM transition lists were last used in 2010
**      See https://dms2.pnl.gov/mrm_list_attachment/report
**
**  Arguments:
**    _id                       Attachment ID
**    _attachmentType           Attachment type, typically 'MRM Transition List'
**    _attachmentName           Attachment name
**    _attachmentDescription    Attachment description
**    _ownerUsername            Owner username
**    _active                   Active: 'Y' or 'N'
**    _contents                 Contents (see below)
**    _fileName                 Attachment filename, e.g. abs_VP2P105_MRM_transitions_min3V_set12.csv
**    _mode                     Mode: 'add' or 'update'
**    _message                  Status message
**    _returnCode               Return code
**    _callingUser              Username of the calling user
**
**  Example value for _contents
**      PARENT,FRAGMENT,VOLTAGE
**      922.99,1391.72,27
**      922.99,1190.64,27
**      922.99,1077.56,27
**      922.99,964.48,27
**      922.99,851.39,27
**      605.33,933.5,18
**      605.33,796.44,18
**      605.33,709.41,18
**      605.33,638.37,18
**      605.33,524.33,18
**      ...
**
**  Auth:   grk
**  Date:   03/24/2009
**  Date:   07/22/2010 grk -- allowed update mode
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/19/2023 mem - Ported to PostgreSQL
**          01/03/2024 mem - Update warning message
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _id                    := Coalesce(_id, 0);
    _attachmentType        := Trim(Coalesce(_attachmentType, ''));
    _attachmentName        := Trim(Coalesce(_attachmentName, ''));
    _attachmentDescription := Trim(Coalesce(_attachmentDescription, ''));
    _ownerUsername         := Trim(Coalesce(_ownerUsername, ''));
    _active                := Trim(Upper(Coalesce(_active, '')));
    _contents              := Trim(Coalesce(_contents, ''));
    _fileName              := Trim(Coalesce(_fileName, ''));
    _mode                  := Trim(Lower(Coalesce(_mode, '')));

    If _attachmentType = '' Then
        _message := 'Attachment type cannot be an empty string';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _attachmentName = '' Then
        _message := 'Attachment name cannot be an empty string';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If _active::citext IN ('Yes', '1') Then
        _active = 'Y';
    End If;

    If _active::citext IN ('No', '0') Then
        _active = 'N';
    End If;

    If Not _active IN ('Y', 'N') Then
        _message := 'Active must be "Y" or "N"';
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If _contents = '' Then
        _message := 'Contents name cannot be an empty string';
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    If _fileName = '' Then
        _message := 'File name cannot be an empty string';
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'add' And Exists (SELECT attachment_id FROM t_attachments WHERE attachment_name = _attachmentName) Then
        _message := format('Cannot add a new attachment named "%s" since one with that name already exists', _attachmentName);
        RAISE EXCEPTION '%', _message;
    End If;


    If _mode = 'update' And Not Exists (SELECT attachment_id FROM t_attachments WHERE attachment_id = _id) Then
        _message := format('Cannot update attachment "%s" since attachment ID %s does not exist', _attachmentName, _id);
        RAISE EXCEPTION '%', _message;
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

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_attachments
        SET attachment_type        = _attachmentType,
            attachment_name        = _attachmentName,
            attachment_description = _attachmentDescription,
            owner_username         = _ownerUsername,
            active                 = _active,
            contents               = _contents,
            file_name              = _fileName
        WHERE attachment_id = _id;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_attachments(INOUT _id integer, IN _attachmenttype text, IN _attachmentname text, IN _attachmentdescription text, IN _ownerusername text, IN _active text, IN _contents text, IN _filename text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_attachments(INOUT _id integer, IN _attachmenttype text, IN _attachmentname text, IN _attachmentdescription text, IN _ownerusername text, IN _active text, IN _contents text, IN _filename text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_attachments(INOUT _id integer, IN _attachmenttype text, IN _attachmentname text, IN _attachmentdescription text, IN _ownerusername text, IN _active text, IN _contents text, IN _filename text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateAttachments';

