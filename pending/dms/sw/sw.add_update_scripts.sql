--
CREATE OR REPLACE PROCEDURE sw.add_update_scripts
(
    _script text,
    _description text,
    _enabled text,
    _resultsTag text,
    _backfillToDMS text,
    _contents text,
    _parameters text,
    _fields text,
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
**      Adds new or edits existing T_Scripts
**
**  Arguments:
**    _mode   'add' or 'update'
**
**  Auth:   grk
**  Date:   09/23/2008 grk - Initial Veresion
**          03/24/2009 mem - Now calling Alter_Entered_By_User when _callingUser is defined
**          10/06/2010 grk - Added _parameters field
**          12/01/2011 mem - Expanded _description to varchar(2000)
**          01/09/2012 mem - Added parameter _backfillToDMS
                           - Changed ID field in T_Scripts to a non-identity based int
**          08/13/2013 mem - Added _fields field  (used by MAC Job Wizard on DMS website)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _existingRowCount int := 0;
    _id int;
    _backFill int;
    _scriptIDNew int := 1;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
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

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _description :=   Trim(Coalesce(_description, ''));
    _enabled :=       Trim(Upper(Coalesce(_enabled, 'Y')));
    _backfillToDMS := Trim(Upper(Coalesce(_backfillToDMS, 'Y')));
    _mode :=          Trim(Lower(Coalesce(_mode, '')));
    _callingUser :=   Coalesce(_callingUser, '');

    If _backfillToDMS = 'Y' Then
        _backFill := 1;
    ElsIf _backfillToDMS = 'N' Then
        _backFill := 0;
    Else
        _message := 'BackfillToDMS must be be "Y" or "N"';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    Else

    End If;

    If _description = '' Then
        _message := 'Description cannot be blank';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If Not _mode::citext In ('add', 'update') Then
        _message := format('Unknown Mode: %s', _mode);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    SELECT Count(*)
    INTO _existingRowCount
    FROM sw.t_scripts
    WHERE script = _script;

    -- Cannot update a non-existent entry
    --
    If _mode = 'update' And _existingRowCount = 0 Then
        _message := format('Could not find "%s" in database', _script);
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    -- Cannot add an existing entry
    --
    If _mode = 'add' And _existingRowCount > 0 Then
        _message := format('Script "%s" already exists in database', _script);
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        SELECT Coalesce(MAX(script_id), 0) + 1
        INTO _scriptIDNew
        FROM sw.t_scripts;

        INSERT INTO sw.t_scripts (
            script_id,
            script,
            description,
            enabled,
            results_tag,
            backfill_to_dms,
            contents,
            parameters,
            fields
        ) VALUES (
            _scriptIDNew,
            _script,
            _description,
            _enabled,
            _resultsTag,
            _backFill,
            _contents,
            _parameters,
            _fields
        )
        RETURNING script_id
        INTO _id;

        -- If _callingUser is defined, update entered_by in sw.t_scripts_history
        If char_length(_callingUser) > 0 And Not _id Is Null Then
            CALL alter_entered_by_user ('sw.t_scripts_history', 'script_id', _id, _callingUser);
        End If;

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE sw.t_scripts
        SET
          description = _description,
          enabled = _enabled,
          results_tag = _resultsTag,
          backfill_to_dms = _backFill,
          contents = _contents,
          parameters = _parameters,
          fields = _fields
        WHERE script = _script;

        -- If _callingUser is defined, update entered_by in sw.t_scripts_history
        If char_length(_callingUser) > 0 Then

            SELECT script_id
            INTO _id
            FROM sw.t_scripts
            WHERE script = _script;

            If FOUND And Not _id Is Null Then
                CALL alter_entered_by_user ('sw.t_scripts_history', 'script_id', _id, _callingUser);
            End If;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.add_update_scripts IS 'AddUpdateScripts';
