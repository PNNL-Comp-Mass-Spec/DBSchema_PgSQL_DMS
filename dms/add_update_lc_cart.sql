--
-- Name: add_update_lc_cart(integer, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_lc_cart(INOUT _id integer, IN _cartname text, IN _cartdescription text, IN _cartstate text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing LC Cart
**
**  Arguments:
**    _id               LC cart ID
**    _cartName         LC cart name
**    _cartDescription  Cart description
**    _cartState        Cart state: 'In Service', 'Out of Service', or 'Retired'
**    _mode             Mode: 'add' or 'update'
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   02/23/2006
**          03/03/2006 grk - Fixed problem with duplicate entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/10/2018 mem - Fix bug checking for duplicate carts when adding a new cart
**          04/11/2022 mem - Check for whitespace in _cartName
**          01/12/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**          07/19/2025 mem - Raise an exception if _mode is undefined or unsupported
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _cartStateID int := 0;
    _currentName citext := '';

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

        _cartName        := Trim(Coalesce(_cartName, ''));
        _cartDescription := Trim(Coalesce(_cartDescription, ''));
        _cartState       := Trim(Coalesce(_cartState, ''));
        _mode            := Trim(Lower(Coalesce(_mode, '')));

        If _mode = '' Then
            RAISE EXCEPTION 'Empty string specified for parameter _mode';
        ElsIf Not _mode IN ('add', 'update', 'check_add', 'check_update') Then
            RAISE EXCEPTION 'Unsupported value for parameter _mode: %', _mode;
        End If;

        If public.has_whitespace_chars(_cartName, _allowspace => false) Then
            If Position(chr(9) In _cartName) > 0 Then
                RAISE EXCEPTION 'LC cart name cannot contain tabs';
            Else
                RAISE EXCEPTION 'LC cart name cannot contain spaces';
            End If;
        End If;

        If _cartName = '' Then
            RAISE EXCEPTION 'LC cart name must be specified';
        End If;

        If _cartDescription = '' Then
            RAISE EXCEPTION 'LC cart description must be specified';
        End If;

        If _cartState = '' Then
            RAISE EXCEPTION 'LC cart state must be specified';
        End If;

        ---------------------------------------------------
        -- Resolve cart state name to ID
        ---------------------------------------------------

        SELECT cart_state_id
        INTO _cartStateID
        FROM t_lc_cart_state_name
        WHERE cart_state = _cartState::citext;

        If Not FOUND Then
            _message := 'Could not resolve state name to ID';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Verify whether entry exists or not
        ---------------------------------------------------

        If _mode = 'add' Then
            _id := 0;

            If Exists (SELECT cart_name FROM t_lc_cart WHERE cart_name = _cartName::citext) Then
                _message := format('Cannot add: Entry already exists for cart "%s"', _cartName);
                RAISE WARNING '%', _message;

                _returnCode := 'U5202';
                RETURN;
            End If;
        End If;

        If _mode = 'update' Then
            If _id Is Null Then
                RAISE EXCEPTION 'Cannot update: cart ID is null';
            End If;

            If Not Exists (SELECT cart_id FROM t_lc_cart WHERE cart_id = _id) Then
                _message := format('Cannot update: cart cart_id "%s" does not exist', _id);
                RAISE WARNING '%', _message;

                _returnCode := 'U5203';
                RETURN;
            End If;

            SELECT cart_name
            INTO _currentName
            FROM t_lc_cart
            WHERE cart_id = _id;

            If _cartName::citext <> _currentName And Exists (SELECT cart_name FROM t_lc_cart WHERE cart_name = _cartName::citext) Then
                _message := format('Cannot rename - Entry already exists for cart "%s"', _cartName);
                RAISE WARNING '%', _message;

                _returnCode := 'U5204';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            INSERT INTO t_lc_cart (
                cart_name,
                cart_state_id,
                cart_description
            ) VALUES (
                _cartName,
                _cartStateID,
                _cartDescription
            )
            RETURNING cart_id
            INTO _id;
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_lc_cart
            SET cart_name        = _cartName,
                cart_state_id    = _cartStateID,
                cart_description = _cartDescription
            WHERE cart_id = _id;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; LC Cart %s', _exceptionMessage, _cartName);

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


ALTER PROCEDURE public.add_update_lc_cart(INOUT _id integer, IN _cartname text, IN _cartdescription text, IN _cartstate text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_lc_cart(INOUT _id integer, IN _cartname text, IN _cartdescription text, IN _cartstate text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_lc_cart(INOUT _id integer, IN _cartname text, IN _cartdescription text, IN _cartstate text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateLCCart';

