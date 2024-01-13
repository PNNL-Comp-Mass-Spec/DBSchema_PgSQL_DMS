--
-- Name: add_update_instrument_config_history(integer, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_instrument_config_history(INOUT _id integer, IN _instrument text, IN _dateofchange text, IN _postedby text, IN _description text, IN _note text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing instrument config entry
**
**  Arguments:
**    _id               Input/output: entry_id in t_instrument_config_history
**    _instrument       Instrument name
**    _dateOfChange     Entry date
**    _postedBy         Username of the person associated with the config entry
**    _description      Description of the task, e.g. 'Cleaned source', 'FT Mass Cal', or 'Liquid Nitrogen Fill'
**    _note             Detailed notes regarding the task
**    _mode             Mode: 'add' or 'update'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   09/30/2008
**          03/19/2012 grk - Added 'PostedBy'
**          06/13/2017 mem - Use SCOPE_IDENTITY
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/30/2018 mem - Make _id an output parameter
**                           Validate _dateOfChange
**          01/11/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _validatedDate timestamp;
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

    _instrument   := Trim(Coalesce(_instrument));
    _dateOfChange := Trim(Coalesce(_dateOfChange));
    _postedBy     := Trim(Coalesce(_postedBy));
    _description  := Trim(Coalesce(_description));
    _note         := Trim(Coalesce(_note));
    _callingUser  := Trim(Coalesce(_callingUser, ''));
    _mode         := Trim(Lower(Coalesce(_mode, '')));

    If _instrument = '' Then
        _message := 'Instrument name must be defined';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _callingUser = '' Then
        _callingUser := SESSION_USER;
    End If;

    If _postedBy = '' Then
        _postedBy := _callingUser;
    End If;

    _validatedDate := public.try_cast(_dateOfChange, null::timestamp);

    If _validatedDate Is Null Then
        _message := format('Date of change is not a valid date: "%s"', _dateOfChange);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not _mode In ('add', 'update') Then
        _message := format('Mode should be "add" or "update, not "%s"', _mode);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        If _id Is Null Then
            _message := 'Cannot update: instrument config ID cannot be null';
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';
            RETURN;
        End If;

        If Not Exists (SELECT entry_id FROM t_instrument_config_history WHERE entry_id = _id) Then
            _message := format('Cannot update: instrument config ID %s does not exist', _id);
            RAISE WARNING '%', _message;

            _returnCode := 'U5204';
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        INSERT INTO t_instrument_config_history (
            instrument,
            date_of_change,
            description,
            note,
            entered,
            entered_by
        ) VALUES (
            _instrument,
            _validatedDate,
            _description,
            _note,
            CURRENT_TIMESTAMP,
            _postedBy
        )
        RETURNING entry_id
        INTO _id;

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_instrument_config_history
        SET instrument     = _instrument,
            date_of_change = _validatedDate,
            description    = _description,
            note           = _note,
            entered_by     = _postedBy
        WHERE entry_id = _id;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_instrument_config_history(INOUT _id integer, IN _instrument text, IN _dateofchange text, IN _postedby text, IN _description text, IN _note text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_instrument_config_history(INOUT _id integer, IN _instrument text, IN _dateofchange text, IN _postedby text, IN _description text, IN _note text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_instrument_config_history(INOUT _id integer, IN _instrument text, IN _dateofchange text, IN _postedby text, IN _description text, IN _note text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateInstrumentConfigHistory';

