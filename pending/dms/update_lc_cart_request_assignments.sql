--
CREATE OR REPLACE PROCEDURE public.update_lc_cart_request_assignments
(
    _cartAssignmentList text,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Set LC cart and col assignments for requested runs
**
**  Example XML for _cartAssignmentList
**      <r rq="543451" ct="Andromeda" co="1" cg="" />
**      <r rq="543450" ct="Andromeda" co="2" cg="" />
**      <r rq="543449" ct="Andromeda" co="1" cg="Tiger_Jup_2D_Peptides_20uL" />
**
**  Where rq is the request ID, ct is the cart name, co is the column number, and cg is the cart config name
**  See method saveChangesToDatabase below lc_cart_request_loading in file javascript/lcmd.js
**
**  Arguments:
**    _cartAssignmentList   XML (see above)
**    _mode                 Unused, but likely 'update'
**
**  Auth:   grk
**  Date:   03/10/2010
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          11/07/2016 mem - Add optional logging via post_log_entry
**          02/27/2017 mem - Add support for cart config name
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _xml AS xml;
    _debugMode boolean := false;
    _debugMsg text;
    _requestCountInXML int;
    _invalidCart text := '';
    _invalidCartConfig text := '';
    _firstLocked int;
    _lastLocked int;
    _deleteCount int;
    _updateRowCount int;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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

    -----------------------------------------------------------
    -- Convert _cartAssignmentList to rooted XML
    -----------------------------------------------------------

    _xml := public.try_cast('<root>' || _cartAssignmentList || '</root>', null::xml);

    If _xml Is Null Then
        _message := 'Cart assignment list is not valid XML';
        RAISE EXCEPTION '%', _message;
    End If;

    -- Change this to true to enable debugging

    If _debugMode Then
        _debugMsg := Cast(_cartAssignmentList As text);
        CALL post_log_entry ('Debug', _debugMsg, 'Update_LC_Cart_Request_Assignments');
    End If;

    -----------------------------------------------------------
    -- Create and populate temp table with block assignments
    -----------------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_BlockingInfo (
        request_id int,
        cart_name text,
        cart_config_name text,
        cart_column text,           -- Cart column number
        cart_id int NULL,
        cart_config_id int NULL,
        locked citext NULL
    )

    INSERT INTO Tmp_BlockingInfo ( request_id, cart_name, cart_config_name, cart_column)
    SELECT XmlQ.request_id, XmlQ.cart, XmlQ.cartConfig, XmlQ.cart_column
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _xml As rooted_xml
             ) Src,
             XMLTABLE('//root/r'
                      PASSING Src.rooted_xml
                      COLUMNS request_id citext PATH '@rq',
                              cart citext PATH '@ct',
                              cartConfig citext PATH '@cg',
                              cart_column citext PATH '@co')
         ) XmlQ;
    --
    GET DIAGNOSTICS _requestCountInXML = ROW_COUNT;

    UPDATE Tmp_BlockingInfo
    SET cart_config_name = ''
    WHERE cart_config_name Is Null;

    -----------------------------------------------------------
    -- Resolve cart name to cart ID
    -----------------------------------------------------------
    --
    UPDATE Tmp_BlockingInfo
    SET cart_id = t_lc_cart.cart_id
    FROM t_lc_cart
    WHERE Tmp_BlockingInfo.cart_name = t_lc_cart.cart_name;

    If Exists (SELECT * FROM Tmp_BlockingInfo WHERE cart_id IS NULL) Then

        SELECT cart_name
        INTO _invalidCart
        FROM Tmp_BlockingInfo
        WHERE cart_id IS NULL
        LIMIT 1;

        If Coalesce(_invalidCart, '') = '' Then
            _message := 'Cart names cannot be blank';
        Else
            _message := format('Invalid cart name: %s', _invalidCart);
        End If;

        _returnCode := 'U5201';

        DROP TABLE Tmp_BlockingInfo;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Resolve cart config name to cart config ID
    -----------------------------------------------------------
    --
    UPDATE Tmp_BlockingInfo
    SET cart_config_id = CartConfig.cart_config_id
    FROM t_lc_cart_configuration AS CartConfig
    WHERE Tmp_BlockingInfo.cart_config_name = CartConfig.cart_config_name;

    If Exists (SELECT * FROM Tmp_BlockingInfo WHERE cart_config_name <> '' AND cart_config_id IS NULL) Then

        SELECT cart_config_name
        INTO _invalidCartConfig
        FROM Tmp_BlockingInfo
        WHERE cart_config_name <> '' AND cart_config_id IS NULL
        LIMIT 1;

        _message := format('Invalid cart config name: %s', _invalidCartConfig);
        _returnCode := 'U5202';

        DROP TABLE Tmp_BlockingInfo;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Batch info
    -----------------------------------------------------------
    --
    UPDATE Tmp_BlockingInfo
    SET locked = RRB.Locked
    FROM t_requested_run RR
         INNER JOIN t_requested_run_batches AS RRB
           ON RR.batch_id = RRB.batch_id
    WHERE Tmp_BlockingInfo.request_id = RR.request_id;

    -----------------------------------------------------------
    -- Check for locked batches
    -----------------------------------------------------------

    If Exists (SELECT * FROM Tmp_BlockingInfo WHERE locked = 'Yes') Then

        SELECT MIN(request),
               MAX(request)
        INTO _firstLocked, _lastLocked
        FROM Tmp_BlockingInfo
        WHERE locked = 'Yes'

        If _firstLocked = _lastLocked Then
            _message := format('Cannot change requests in locked batches; request %s is locked', _firstLocked);
        Else
            _message := format('Cannot change requests in locked batches; locked requests include %s and %s', _firstLocked, _lastLocked);
        End If;

        _returnCode := 'U5203';

        DROP TABLE Tmp_BlockingInfo;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Disregard unchanged requests
    -----------------------------------------------------------
    --
    DELETE FROM Tmp_BlockingInfo
    WHERE request_id IN ( SELECT request
                          FROM Tmp_BlockingInfo
                            INNER JOIN t_requested_run AS RR
                              ON Tmp_BlockingInfo.request_id = RR.request_id AND
                                 Tmp_BlockingInfo.cart_id = RR.cart_id AND
                                 Coalesce(Tmp_BlockingInfo.cart_config_id, 0) = Coalesce(RR.cart_config_id, 0) AND
                                 public.try_cast(Tmp_BlockingInfo.cart_column, 0) = Coalesce(RR.cart_column, 0) );
    --
    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _debugMode Then
        If _requestCountInXML = _deleteCount Then
            _debugMsg := format('All %s requests were unchanged; nothing to do', _requestCountInXML);
        ElsIf _deleteCount = 0
            _debugMsg := format('Will update all %s requests', _requestCountInXML);
        Else
            _debugMsg := format('Will update %s of %s requests', _requestCountInXML - _deleteCount, _requestCountInXML);
        End If;

        CALL post_log_entry ('Debug', _debugMsg, 'Update_LC_Cart_Request_Assignments');

    End If;

    -----------------------------------------------------------
    -- Update requested runs
    -----------------------------------------------------------
    --
    UPDATE t_requested_run
    SET cart_id = Tmp_BlockingInfo.cart_id,
        cart_config_id = Tmp_BlockingInfo.cart_config_id,
        cart_column = Tmp_BlockingInfo.cart_column
    FROM Tmp_BlockingInfo
    WHERE Tmp_BlockingInfo.request_id = t_requested_run.request_id;
    --
    GET DIAGNOSTICS _updateRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s requested %s updated', _updateRowCount, public.check_plural(_updateRowCount, 'run', 'runs'));
    CALL post_usage_log_entry ('Update_LC_Cart_Request_Assignments', _usageMessage);

    DROP TABLE Tmp_BlockingInfo;
END
$$;

COMMENT ON PROCEDURE public.update_lc_cart_request_assignments IS 'UpdateLCCartRequestAssignments';
