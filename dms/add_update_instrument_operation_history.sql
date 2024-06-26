--
-- Name: add_update_instrument_operation_history(integer, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_instrument_operation_history(IN _id integer, IN _instrument text, IN _postedby text, IN _note text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing instrument operation entry
**
**  Arguments:
**    _id           Input/output: entry_id in t_instrument_operation_history
**    _instrument   Instrument name (does not have to be a DMS instrument)
**    _postedBy     Username of the person associated with the operation entry (does not have to be a DMS user)
**    _note         Entry description
**    _mode         Mode: 'add' or 'update'
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user (unused by this procedure)
**
**  Auth:   grk
**  Date:   05/20/2010
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/25/2017 mem - Require that _instrument and _note be defined
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/02/2017 mem - Assure that the username is properly capitalized
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          01/12/2024 mem - Ported to PostgreSQL
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
    _userID int;
    _matchCount int;
    _newUsername text;

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

        _instrument := Trim(Coalesce(_instrument, ''));
        _postedBy   := Trim(Coalesce(_postedBy, ''));
        _note       := Trim(Coalesce(_note, ''));
        _mode       := Trim(Lower(Coalesce(_mode, '')));

        If _instrument = '' Then
            RAISE EXCEPTION 'Instrument name must be specified';
        End If;

        If _note = '' Then
            RAISE EXCEPTION 'Operations note must be specified';
        End If;

        If _postedBy = '' Then
            RAISE EXCEPTION 'Posted by person must be specified';
        End If;

        If _mode = 'update' And _id Is Null Then
            RAISE EXCEPTION 'ID cannot be null when updating a note';
        End If;

        ---------------------------------------------------
        -- Resolve poster username
        ---------------------------------------------------

        _userID := public.get_user_id(_postedBy);

        If _userID > 0 Then
            -- Function get_user_id() recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _postedBy contains simply the username

            SELECT username
            INTO _postedBy
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _postedBy
            -- Try to auto-resolve the name

            CALL public.auto_resolve_name_to_username (
                            _postedBy,
                            _matchCount       => _matchCount,   -- Output
                            _matchingUsername => _newUsername,  -- Output
                            _matchingUserID   => _userID);      -- Output

            If _matchCount = 1 Then
                -- Single match found; update _postedBy
                _postedBy := _newUsername;
            End If;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            If Not Exists (SELECT entry_id FROM t_instrument_operation_history WHERE entry_id = _id) Then
                RAISE EXCEPTION 'Cannot update: instrument operation history ID % does not exist', _id;
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_instrument_operation_history (
                instrument,
                entered_by,
                note
            ) VALUES (
                _instrument,
                _postedBy,
                _note
            )
            RETURNING entry_id
            INTO _id;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_instrument_operation_history
            SET instrument = _instrument,
                note       = _note
            WHERE entry_id = _id;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            If _instrument Is Null Then
                _logMessage := _exceptionMessage;
            Else
                _logMessage := format('%s; Instrument %s', _exceptionMessage, _instrument);
            End If;

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.add_update_instrument_operation_history(IN _id integer, IN _instrument text, IN _postedby text, IN _note text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_instrument_operation_history(IN _id integer, IN _instrument text, IN _postedby text, IN _note text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_instrument_operation_history(IN _id integer, IN _instrument text, IN _postedby text, IN _note text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateInstrumentOperationHistory';

