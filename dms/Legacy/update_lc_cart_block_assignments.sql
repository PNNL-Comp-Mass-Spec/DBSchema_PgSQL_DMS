--
-- Name: update_lc_cart_block_assignments(text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_lc_cart_block_assignments(IN _cartassignmentlist text, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update LC cart and column assignments for requested run blocks
**
**      This procedure is obsolete since blocks are now tracked by block and run_order in t_requested_run; the procedure was last used in 2012
**
**      Example XML for _cartAssignmentList
**        <r bt="3373" bk="1" ct="Earth" co="1" />
**        <r bt="3373" bk="2" ct="Earth" co="2" />
**        <r bt="3373" bk="3" ct="Earth" co="3" />
**        <r bt="3373" bk="4" ct="Earth" co="4" />
**
**      Where 'bt' is the batch ID, 'bk' is the block number, 'ct' is the cart name, and 'co' is the column number
**
**  Arguments:
**    _cartAssignmentList   Blocking info XML (see above)
**    _mode                 Unused, but likely 'update'
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   02/15/2010
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          11/07/2016 mem - Add optional logging via post_log_entry
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/03/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _updateCount int;
    _xml xml;
    _usageMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    -- Uncomment to log the XML for debugging purposes
    -- CALL post_log_entry ('Debug', _cartAssignmentList, 'Update_LC_Cart_Block_Assignments');

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
        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        _cartAssignmentList := Trim(Coalesce(_cartAssignmentList, ''));
        _mode               := Trim(Lower(Coalesce(_mode, '')));

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

        CREATE TEMP TABLE Tmp_BlockingInfo (
            batch_id int,
            block int,
            cart citext,
            cart_id int NULL,
            col int
        );

        INSERT INTO Tmp_BlockingInfo (batch_id, block, cart, col)
        SELECT XmlQ.batch_id, XmlQ.block, Trim(XmlQ.cart), XmlQ.col
        FROM (
            SELECT xmltable.*
            FROM ( SELECT _xml AS rooted_xml
                 ) Src,
                 XMLTABLE('//root/r'
                          PASSING Src.rooted_xml
                          COLUMNS batch_id int  PATH '@bt',
                                  block    int  PATH '@bk',
                                  cart     text PATH '@ct',
                                  col      int  PATH '@co')
             ) XmlQ;

        -----------------------------------------------------------
        -- Resolve cart name to cart ID
        -----------------------------------------------------------

        UPDATE Tmp_BlockingInfo
        SET cart_id = t_lc_cart.cart_id
        FROM t_lc_cart
        WHERE Tmp_BlockingInfo.cart = t_lc_cart.cart_name;

        -- If any cart names were unrecognized, use 1 for cart_id
        UPDATE Tmp_BlockingInfo
        SET cart_id = 1
        WHERE cart_id IS NULL;

        -----------------------------------------------------------
        -- Create and populate temp table with request assignments
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_RequestsInBlock (
            request_id int,
            cart_id int,
            col int
        );

        INSERT INTO Tmp_RequestsInBlock (request_id, cart_id, col)
        SELECT RR.request_id,
               RR.cart_id,
               BI.col
        FROM t_requested_run RR
             INNER JOIN Tmp_BlockingInfo BI
               ON RR.batch_ID = BI.batch_id AND
                  RR.block = BI.block;

        -----------------------------------------------------------
        -- Update requested runs
        -----------------------------------------------------------

        UPDATE t_requested_run
        SET cart_id = BI.cart_id,
            cart_column = BI.col
        FROM Tmp_RequestsInBlock BI
        WHERE t_requested_run.request_id = BI.request_id;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Updated %s requested %s', _updateCount, public.check_plural(_updateCount, 'run', 'runs'));

    CALL post_usage_log_entry ('update_lc_cart_block_assignments', _usageMessage);

    DROP TABLE IF EXISTS Tmp_BlockingInfo;
    DROP TABLE IF EXISTS Tmp_RequestsInBlock;
END
$$;


ALTER PROCEDURE public.update_lc_cart_block_assignments(IN _cartassignmentlist text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_lc_cart_block_assignments(IN _cartassignmentlist text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_lc_cart_block_assignments(IN _cartassignmentlist text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'UpdateLCCartBlockAssignments';

