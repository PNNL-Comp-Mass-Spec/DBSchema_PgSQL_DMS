--
-- Name: add_update_wellplate(text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_wellplate(INOUT _wellplatename text, IN _description text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing wellplate
**
**  Arguments:
**    _wellplateName    Wellplate name
**    _description      Description
**    _mode             Mode: 'add', 'update', or 'assure'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   07/23/2009
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/25/2022 mem - Rename parameter to _wellplate
**          12/03/2023 mem - Ported to PostgreSQL
**          01/03/2024 mem - Update warning messages
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _idx int;
    _existingID int;
    _existingCount int;
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
    -- Optionally generate name
    ---------------------------------------------------

    _wellplateName := Trim(Coalesce(_wellplateName, ''));
    _description   := Trim(Coalesce(_description, ''));
    _mode          := Trim(Lower(Coalesce(_mode, '')));

    If Lower(_wellplateName) = '(generate name)' Then

        SELECT MAX(wellplate_id) + 1
        INTO _idx
        FROM t_wellplates;

        If Coalesce(_idx, 0) < 1000 Then
            _idx := 1000;
        End If;

        _wellplateName := format('WP-%s', _idx);
    End If;

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    SELECT wellplate_id
    INTO _existingID
    FROM t_wellplates
    WHERE wellplate = _wellplateName::citext;
    --
    GET DIAGNOSTICS _existingCount = ROW_COUNT;

    ---------------------------------------------------
    -- If mode is 'assure', add a new entry if it doesn't exist
    ---------------------------------------------------

    If _mode = 'assure' And (_existingCount = 0 Or _existingID = 0) Then
        _mode := 'add';
    End If;

    ---------------------------------------------------
    -- Cannot update a non-existent entry
    ---------------------------------------------------

    If _mode = 'update' And (_existingCount = 0 Or _existingID = 0) Then
        _message := format('Cannot update: wellplate "%s" does not exist', _wellplateName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Cannot add a matching entry
    ---------------------------------------------------

    If _mode = 'add' And _existingID <> 0 Then
        _message := format('Cannot add: wellplate "%s" already exists', _wellplateName);
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
        );

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_wellplates
        SET wellplate   = _wellplateName,
            description = _description
        WHERE wellplate::citext = _wellplateName;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_wellplate(INOUT _wellplatename text, IN _description text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_wellplate(INOUT _wellplatename text, IN _description text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_wellplate(INOUT _wellplatename text, IN _description text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateWellplate';

