--
CREATE OR REPLACE PROCEDURE public.add_update_instrument_operation_history
(
    _id int,
    _instrument text,
    _postedBy text,
    _note text,
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
**      Adds new or edits existing item in T_Instrument_Operation_History
**
**  Arguments:
**    _mode   'add' or 'update'
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _userID int;
    _matchCount int;
    _newUsername text;
    _tmp int := 0;
    _logMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    BEGIN

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        If Coalesce(_instrument, '') = '' Then
            RAISE EXCEPTION 'Instrument name not defined';
        End If;

        If _note Is Null Then
            RAISE EXCEPTION 'Note cannot be blank';
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        If _mode = 'update' and _id is null Then
            RAISE EXCEPTION 'ID cannot be null when updating a note';
        End If;

        ---------------------------------------------------
        -- Resolve poster username
        ---------------------------------------------------

        _userID := public.get_user_id (_postedBy);

        If _userID > 0 Then
            -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _postedBy contains simply the username
            --
            SELECT username
            INTO _postedBy
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _postedBy
            -- Try to auto-resolve the name

            Call auto_resolve_name_to_username (_postedBy, _matchCount => _matchCount, _matchingUsername => _newUsername, _matchingUserID => _userID);

            If _matchCount = 1 Then
                -- Single match found; update _postedBy
                _postedBy := _newUsername;
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry
            --
            SELECT entry_id
            INTO _tmp
            FROM  t_instrument_operation_history
            WHERE (entry_id = _id)

            If Not FOUND Then
                RAISE EXCEPTION 'No entry could be found in database for update';
            End If;
        End If;

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

        End If; -- add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If _mode = 'update' Then
            --
            UPDATE t_instrument_operation_history
            SET instrument = _instrument,
                note = _note
            WHERE entry_id = _id;

        End If; -- update mode

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Instrument %s', _exceptionMessage, _instrument);

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

COMMENT ON PROCEDURE public.add_update_instrument_operation_history IS 'AddUpdateInstrumentOperationHistory';