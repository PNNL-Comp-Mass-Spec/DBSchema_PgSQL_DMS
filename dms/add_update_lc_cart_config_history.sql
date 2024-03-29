--
-- Name: add_update_lc_cart_config_history(integer, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_lc_cart_config_history(IN _id integer, IN _cart text, IN _dateofchange text, IN _postedby text, IN _description text, IN _note text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing cart config history entry
**
**  Arguments:
**    _id               Entry_ID in t_lc_cart_config_history
**    _cart             Cart name
**    _dateOfChange     Date for the cart config history item
**    _postedBy         Username of the person associated with the cart config history item
**    _description      General description of the task, e.g. 'Replaced rotors' or 'Replaced Syringe'
**    _note             Additional details
**    _mode             Mode: 'add' or 'update'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   03/09/2011
**          03/26/2012 grk - Added _postedBy
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          11/25/2023 mem - Validate LC cart name
**          01/12/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _entryDate timestamp;
    _validatedName text;
    _logErrors boolean := false;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _cart        := Trim(Coalesce(_cart, ''));
        _postedBy    := Trim(Coalesce(_postedBy, ''));
        _description := Trim(Coalesce(_description, ''));
        _note        := Trim(Coalesce(_note, ''));
        _callingUser := Trim(Coalesce(_callingUser, ''));
        _mode        := Trim(Lower(Coalesce(_mode, '')));

        If _cart = '' Then
            RAISE EXCEPTION 'LC cart name must be specified';
        End If;

        If _description = '' Then
            RAISE EXCEPTION 'Description must be specified';
        End If;

        _entryDate := public.try_cast(_dateOfChange, null::timestamp);

        If _entryDate Is Null Then
            _entryDate := CURRENT_TIMESTAMP;
        End If;

        If _postedBy = '' Then
            If _callingUser = '' Then
                _postedBy := SESSION_USER;
            Else
                _postedBy := _callingUser;
            End If;
        End If;

        -- Verify that the cart exists and capitalize the name, if necessary
        SELECT cart_name
        INTO _validatedName
        FROM t_lc_cart
        WHERE cart_name = _cart::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Unrecognized LC cart name: %', _cart;
        End If;

        _cart := _validatedName;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            If _id Is Null Then
                RAISE EXCEPTION 'Cannot update: cart ID cannot be null';
            End If;

            If Not Exists (SELECT entry_id FROM t_lc_cart_config_history WHERE entry_id = _id) Then
                RAISE EXCEPTION 'Cannot update: cart config history ID % does not exist', _id;
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_lc_cart_config_history (
                cart,
                date_of_change,
                description,
                note,
                entered_by
            ) VALUES (
                _cart,
                _entryDate,
                _description,
                _note,
                _postedBy
            )
            RETURNING entry_id
            INTO _id;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_lc_cart_config_history
            SET cart           = _cart,
                date_of_change = _entryDate,
                description    = _description,
                note           = _note,
                entered_by     = _postedBy
            WHERE entry_id = _id;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _id Is Null Then
            _logMessage := format('%s; Cart %s, Null Cart ID', _exceptionMessage, Coalesce(_cart, ''));
        Else
            _logMessage := format('%s; Cart %s, ID %s', _exceptionMessage, Coalesce(_cart, ''), _id);
        End If;

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => _logErrors);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.add_update_lc_cart_config_history(IN _id integer, IN _cart text, IN _dateofchange text, IN _postedby text, IN _description text, IN _note text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_lc_cart_config_history(IN _id integer, IN _cart text, IN _dateofchange text, IN _postedby text, IN _description text, IN _note text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_lc_cart_config_history(IN _id integer, IN _cart text, IN _dateofchange text, IN _postedby text, IN _description text, IN _note text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateLCCartConfigHistory';

