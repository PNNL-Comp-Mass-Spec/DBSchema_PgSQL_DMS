--
CREATE OR REPLACE PROCEDURE public.add_update_lc_cart
(
    INOUT _id int,
    _cartName text,
    _cartDescription text,
    _cartState text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
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
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _cartStateID int := 0;
    _currentName text := '';
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

    _cartName        := Trim(Coalesce(_cartName, ''));
    _cartDescription := Trim(Coalesce(_cartDescription, ''));
    _cartState       := Trim(Coalesce(_cartState, ''));
    _mode            := Trim(Lower(Coalesce(_mode, '')));

    If public.has_whitespace_chars(_cartName, _allowspace => false) Then
        If Position(chr(9) In _cartName) > 0 Then
            RAISE EXCEPTION 'LC Cart name cannot contain tabs';
        Else
            RAISE EXCEPTION 'LC Cart name cannot contain spaces';
        End If;
    End If;

    ---------------------------------------------------
    -- Resolve cart state name to ID
    ---------------------------------------------------

    SELECT cart_state_id
    INTO _cartStateID
    FROM t_lc_cart_state_name
    WHERE cart_state = _cartState;

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

        If Exists (SELECT cart_name FROM t_lc_cart WHERE cart_name = _cartName) Then
            _message := format('Cannot add: Entry already exists for cart "%s"', _cartName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;
    End If;

    If _mode = 'update' Then
        If Not Exists (SELECT cart_id FROM t_lc_cart WHERE cart_id = _id) Then
            _message := format('Cannot update: cart cart_id "%s" does not exist', _id);
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';
            RETURN;
        End If;

        SELECT cart_name
        INTO _currentName
        FROM t_lc_cart
        WHERE cart_id = _id

        If _cartName <> _currentName And Exists (SELECT cart_name FROM t_lc_cart WHERE cart_name = _cartName) Then
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
        SET cart_name = _cartName,
            cart_state_id = _cartStateID,
            cart_description = _cartDescription
        WHERE cart_id = _id

    End If;

END
$$;

COMMENT ON PROCEDURE public.add_update_lc_cart IS 'AddUpdateLCCart';
