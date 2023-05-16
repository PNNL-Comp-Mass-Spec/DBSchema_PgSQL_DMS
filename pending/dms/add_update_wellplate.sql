--
CREATE OR REPLACE PROCEDURE public.add_update_wellplate
(
    INOUT _wellplateName text,
    _description text,
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
**      Adds new or edits existing item in T_Wellplates
**
**  Arguments:
**    _mode   'add' or 'update' or 'assure'
**
**  Auth:   grk
**  Date:   07/23/2009
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/25/2022 mem - Rename parameter to _wellplate
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _idx int;
    _existingID int;
    _existingCount int;
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

    ---------------------------------------------------
    -- Optionally generate name
    ---------------------------------------------------

    If _wellplateName = '(generate name)' Then
        --
        SELECT MAX(wellplate_id) + 1
        INTO _idx
        FROM  t_wellplates;

        If Coalesce(_idx, 0) < 1000 Then
            _idx := 1000;
        End If;

        _wellplateName := format('WP-%s', _idx);
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    SELECT wellplate_id
    INTO _existingID
    FROM  t_wellplates
    WHERE wellplate = _wellplateName;
    --
    GET DIAGNOSTICS _existingCount = ROW_COUNT;

    ---------------------------------------------------
    -- In this mode, add new entry if it doesn't exist
    ---------------------------------------------------
    If _mode = 'assure' And (_existingCount = 0 Or _existingID = 0) Then
        _mode := 'add';
    End If;

    ---------------------------------------------------
    -- Cannot update a non-existent entry
    ---------------------------------------------------

    If _mode = 'update' And (_existingCount = 0 Or _existingID = 0) Then
        _message := 'No entry could be found in database for update';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Cannot add a matching entry
    ---------------------------------------------------

    If _mode = 'add' And _existingID <> 0 Then
        _message := 'Cannot add duplicate wellplate name';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    If _mode = 'add' Then

        INSERT INTO t_wellplates (
            wellplate,
            description
        ) VALUES (
            _wellplateName,
            _description
        )

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If _mode = 'update' Then

        UPDATE t_wellplates
        SET wellplate = _wellplateName,
            description = _description
        WHERE wellplate = _wellplateName;

    End If;

END
$$;

COMMENT ON PROCEDURE public.add_update_wellplate IS 'AddUpdateWellplate';
