--
-- Name: do_biomaterial_operation(text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_biomaterial_operation(IN _biomaterialname text, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Perform biomaterial (cell culture) operation defined by _mode
**
**      The only supported mode is 'delete', and biomaterial will only be deleted if its state is 'new' and it is not used by any experiments
**
**  Arguments:
**    _biomaterialName  Biomaterial name
**    _mode             Mode: 'delete'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   06/17/2002
**          03/27/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/04/2024 mem - Delete the biomaterial from t_biomaterial_organisms before deleting from t_biomaterial
**                         - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
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
    _targetType int;
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

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _biomaterialName := Trim(Coalesce(_biomaterialName, ''));
    _mode            := Trim(Lower(Coalesce(_mode, '')));
    _callingUser     := Trim(Coalesce(_callingUser, ''));

    ---------------------------------------------------
    -- Get biomaterial ID
    ---------------------------------------------------

    SELECT Biomaterial_ID
    INTO _biomaterialID
    FROM t_biomaterial
    WHERE Biomaterial_Name = _biomaterialName::citext;

    If Not FOUND Then
        _message := format('Could not get ID for biomaterial "%s"', _biomaterialName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete biomaterial if it is in 'new' state and is not used by any experiments
    ---------------------------------------------------

    If _mode = 'delete' Then

        If Exists (SELECT biomaterial_id FROM t_experiment_biomaterial WHERE biomaterial_id = _biomaterialID) Then
            _message := 'Cannot delete biomaterial that is referenced by any experiments';
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;

        DELETE FROM t_biomaterial_organisms
        WHERE biomaterial_id = _biomaterialID;

        DELETE FROM t_biomaterial
        WHERE biomaterial_id = _biomaterialID;

        -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
        If _callingUser <> '' Then
            _targetType := 2;
            _stateID    := 0;

            CALL public.alter_event_log_entry_user ('public', _targetType, _biomaterialID, _stateID, _callingUser, _message => _alterEnteredByMessage);
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    _message := format('Mode "%s" was unrecognized', _mode);
    RAISE WARNING '%', _message;

    _returnCode := 'U5203';

END
$$;


ALTER PROCEDURE public.do_biomaterial_operation(IN _biomaterialname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE do_biomaterial_operation(IN _biomaterialname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.do_biomaterial_operation(IN _biomaterialname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DoBiomaterialOperation or DoCellCultureOperation';

