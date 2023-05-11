--
CREATE OR REPLACE PROCEDURE public.update_lc_cart_block_assignments
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
**      Set LC cart and column assignments for requested run blocks
**
**  Example XML for _cartAssignmentList
**      <r bt="3373" bk="1" ct="Earth" co="1" />
**      <r bt="3373" bk="2" ct="Earth" co="2" />
**      <r bt="3373" bk="3" ct="Earth" co="3" />
**      <r bt="3373" bk="4" ct="Earth" co="4" />
**
**  Where bt is the batch ID, bk is the block number, ct is the cart name, and co is the column number
**
**  This procedure was last used in 2012
**
**  Arguments:
**    _cartAssignmentList   Blocking info XML (see above)
**    _mode                 Unused, but likely 'update'
**
**  Auth:   grk
**  Date:   02/15/2010
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          11/07/2016 mem - Add optional logging via PostLogEntry
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _xml AS xml;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode:= '';

    -- Uncomment to log the XML for debugging purposes
    -- call PostLogEntry ('Debug', _cartAssignmentList, 'UpdateLCCartBlockAssignments');

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

    -----------------------------------------------------------
    -- Convert _cartAssignmentList to rooted XML
    -----------------------------------------------------------

    _xml := public.try_cast('<root>' || _cartAssignmentList || '</root>', null::xml);

    If _xml Is Null Then
        _message := 'Cart assignment list is not valid XML';
        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------------------
    -- Create and populate temp table with block assignments
    -----------------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_BlockingInfo (
        batch_id int,
        block   int,
        cart    text,
        cart_id  int NULL,
        col     int
    )

    INSERT INTO Tmp_BlockingInfo (batch_id, block, cart, col)
    SELECT XmlQ.batch_id, XmlQ.block, XmlQ.cart, XmlQ.col
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _xml As rooted_xml
             ) Src,
             XMLTABLE('//root/r'
                      PASSING Src.rooted_xml
                      COLUMNS batch_id citext PATH '@bt',
                              block citext PATH '@bk',
                              cart citext PATH '@ct',
                              col citext PATH '@co')
         ) XmlQ;

    -----------------------------------------------------------
    -- Resolve cart name to cart ID
    -----------------------------------------------------------
    --
    UPDATE Tmp_BlockingInfo
    SET cart_id = t_lc_cart.cart_id
    FROM t_lc_cart
    WHERE Tmp_BlockingInfo.cart = t_lc_cart.cart_name;

    -- If any cart names were unrecognized, use 1 for cart_id
    UPDATE Tmp_BlockingInfo
    SET cart_id = 1
    WHERE cart_id Is null;

    -- FUTURE: verify valid cart names

    -----------------------------------------------------------
    -- Create and populate temp table with request assignments
    -----------------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_RequestsInBlock (
        request_id int,
        cart_id  int,
        col     int
    )

    INSERT INTO Tmp_RequestsInBlock( request_id,
                                     cart_id,
                                     col )
    SELECT request_id,
           cart_id,
           col
    FROM t_requested_run RR
         INNER JOIN Tmp_BlockingInfo BI
           ON RR.batch_ID = BI.batch_id AND
              RR.block = BI.block;

    -----------------------------------------------------------
    -- Update requested runs
    -----------------------------------------------------------
    --
    UPDATE t_requested_run
    SET cart_id = BI.cart_id,
        cart_column = BI.col
    FROM Tmp_RequestsInBlock BI
    WHERE t_requested_run.request_id = BI.request_id;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Updated %s requsted %s', _myRowCount, public.check_plural(_myRowCount, 'run', 'runs'));

    Call post_usage_log_entry ('Update_LC_Cart_Block_Assignments', _usageMessage);

    DROP TABLE Tmp_BlockingInfo;
    DROP TABLE Tmp_RequestsInBlock;
END
$$;

COMMENT ON PROCEDURE public.update_lc_cart_block_assignments IS 'UpdateLCCartBlockAssignments';
