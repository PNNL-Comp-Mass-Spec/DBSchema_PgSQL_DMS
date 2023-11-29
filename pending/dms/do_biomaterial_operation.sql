--
CREATE OR REPLACE PROCEDURE public.do_biomaterial_operation
(
    _biomaterialName text,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Perform biomaterial (cell culture) operation defined by _mode
**
**  Arguments:
**    _biomaterialName  Biomaterial name
**    _mode             Mode: 'delete'
**    _message          Output message
**    _returnCode       Return code
**    _callingUser      Calling user username
**
**  Auth:   grk
**  Date:   06/17/2002
**          03/27/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
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

    _result int;
    _biomaterialID int;
    _stateID int;
    _alterEnteredByMessage text;
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
    -- Validate the inputs
    ---------------------------------------------------

    _biomaterialName := Trim(Coalesce(_biomaterialName, ''));
    _mode            := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Get biomaterial ID
    ---------------------------------------------------

    SELECT Biomaterial_ID
    INTO _biomaterialID
    FROM t_biomaterial
    WHERE Biomaterial_Name = _biomaterialName;

    If Not FOUND Then
        _message := format('Could not get ID for biomaterial "%s"', _biomaterialName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Delete biomaterial if it is in 'new' state only
    ---------------------------------------------------

    If _mode = 'delete' Then
        ---------------------------------------------------
        -- Verify that biomaterial is not used by any experiments
        ---------------------------------------------------

        If Exists (SELECT COUNT(biomaterial_id) FROM t_experiment_biomaterial WHERE biomaterial_id = _biomaterialID) Then
            _message := 'Cannot delete biomaterial that is referenced by any experiments';
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Delete the biomaterial
        ---------------------------------------------------

        DELETE FROM t_biomaterial
        WHERE Biomaterial_ID = _biomaterialID

        -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
        If char_length(_callingUser) > 0 Then
            _stateID := 0;

            CALL public.alter_event_log_entry_user ('public', 2, _biomaterialID, _stateID, _callingUser, _message => _alterEnteredByMessage);
        End If;

        RETURN;
    End If; -- mode 'delete'

    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    _message := format('Mode "%s" was unrecognized', _mode);
    RAISE WARNING '%', _message;

    _returnCode := 'U5201';

END
$$;

COMMENT ON PROCEDURE public.do_biomaterial_operation IS 'DoBiomaterialOperation or DoCellCultureOperation';
