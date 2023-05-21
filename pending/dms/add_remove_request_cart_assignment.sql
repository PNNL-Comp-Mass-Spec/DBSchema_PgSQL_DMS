--
CREATE OR REPLACE PROCEDURE public.add_remove_request_cart_assignment
(
    _requestIDList text,
    _cartName text,
    _cartConfigName text = '',
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Replaces existing component at given LC Cart component position with given component
**
**      This procedure is used by method UpdateDMSCartAssignment in LcmsNetDmsTools.dll
**
**  Arguments:
**    _requestIDList    Comma-separated list of run request ID's
**    _cartName         Name of the cart to assign (ignored when _mode is 'Remove')
**    _cartConfigName   Name of the cart config name to assign
**    _mode             'Add' or 'Remove', depending on whether cart is to be assigned to the request or removed from the request
**
**  Auth:   grk
**  Date:   01/16/2008 grk - Initial Release (ticket http://prismtrac.pnl.gov/trac/ticket/715)
**          01/28/2009 dac - Added 'output' keyword to _message parameter
**          02/23/2017 mem - Added parameter _cartConfigName, which is used to populate column cart_config_id
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cartID int := 0;
    _cartConfigID int := null;
    _msg text;
    _list text := '';
BEGIN
    _message := '';
    _returnCode := '';

    _requestIDList := Coalesce(_requestIDList, '');
    If _requestIDList = '' Then
        -- No Request IDs; nothing to do
        RETURN;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Does cart exist?
    ---------------------------------------------------
    --
    --
    If _mode = 'add' Then

        SELECT cart_id
        INTO _cartID
        FROM t_lc_cart
        WHERE cart_name = _cartName;

        If Not FOUND Then
            _returnCode := 'U5217'
            _message := 'Could not resolve cart name to ID';
            RETURN;
        End If;

        If Coalesce(_cartConfigName, '') <> '' Then

            SELECT cart_config_id
            INTO _cartConfigID
            FROM t_lc_cart_configuration
            WHERE (cart_config_name = _cartConfigName);

            If Not FOUND Then
                _msg := format('Could not resolve cart config name "%s" to ID for Request(s) %s', _CartConfigName, _requestIDList);

                CALL post_log_entry ('Error', _msg, 'Add_Remove_Request_Cart_Assignment');
            End If;
        End If;
    Else
        -- Assume _mode is 'remove'

        _cartID := 1; -- no cart
        _cartConfigID := null;
    End If;

    ---------------------------------------------------
    -- Convert delimited list of requests into table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Requests
        requestID int
    );

    INSERT INTO Tmp_Requests( requestID )
    SELECT Value
    FROM public.parse_delimited_integer_list ( _requestIDList, ',' )

    ---------------------------------------------------
    -- Validate request ids
    ---------------------------------------------------
    --
    --
    SELECT string_agg(requestID::text, ', ')
    INTO _list
    FROM Tmp_Requests
    WHERE Not requestID IN (SELECT request_id FROM t_requested_run);

    If Coalesce(_list, '') <> '' Then
        _message := 'The following request IDs are not valid:' || _list;
        _returnCode := 'U5021';

        DROP TABLE Tmp_Requests;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update requests
    ---------------------------------------------------
    --
    UPDATE t_requested_run
    SET cart_id = _cartID,
        cart_config_id = _cartConfigID
    WHERE request_id IN ( SELECT requestID FROM Tmp_Requests )

    DROP TABLE Tmp_Requests;
END
$$;

COMMENT ON PROCEDURE public.add_remove_request_cart_assignment IS 'AddRemoveRequestCartAssignment';
