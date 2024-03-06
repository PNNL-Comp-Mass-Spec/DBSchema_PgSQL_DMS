--
-- Name: update_lc_cart_request_assignments(text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_lc_cart_request_assignments(IN _cartassignmentlist text, IN _mode text, IN _debugmode boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update LC cart and column assignments for requested runs
**
**      Example XML for _cartAssignmentList
**          <r rq="543451" ct="Andromeda" co="1" cg="" />
**          <r rq="543450" ct="Andromeda" co="2" cg="" />
**          <r rq="543449" ct="Andromeda" co="1" cg="Tiger_Jup_2D_Peptides_20uL" />
**
**      Where 'rq' is the request ID, 'ct' is the cart name, 'co' is the column number, and 'cg' is the cart config name
**
**      This procedure is used by function saveChangesToDatabase in file javascript/lcmd.js (below lc_cart_request_loading) on the DMS website
**
**  Arguments:
**    _cartAssignmentList   XML (see above)
**    _mode                 Unused, but likely 'update'
**    _debugMode            When true, log the contents of _cartAssignmentList in t_log_entries, and also log the number of requested runs updated
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   03/10/2010
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          11/07/2016 mem - Add optional logging via post_log_entry
**          02/27/2017 mem - Add support for cart config name
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/05/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _xml xml;
    _debugMsg text;
    _requestCountInXML int;
    _invalidCart text := '';
    _invalidCartConfig text := '';
    _firstLocked int;
    _lastLocked int;
    _deleteCount int;
    _updateRowCount int;
    _usageMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    BEGIN
        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        _cartAssignmentList := Trim(Coalesce(_cartAssignmentList, ''));
        _mode               := Trim(Lower(Coalesce(_mode, '')));
        _debugMode          := Coalesce(_debugMode, false);

        -----------------------------------------------------------
        -- Convert _cartAssignmentList to rooted XML
        -----------------------------------------------------------

        _xml := public.try_cast('<root>' || _cartAssignmentList || '</root>', null::xml);

        If _xml Is Null Then
            _message := 'Cart assignment list is not valid XML';
            RAISE EXCEPTION '%', _message;
        End If;

        If _debugMode Then
            -- Log the XML to t_log_entries since _debugMode is enabled

            _debugMsg := _cartAssignmentList::text;
            CALL post_log_entry ('Debug', _debugMsg, 'Update_LC_Cart_Request_Assignments');
        End If;

        -----------------------------------------------------------
        -- Create and populate temp table with block assignments
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_BlockingInfo (
            request_id int,
            cart_name citext,
            cart_config_name citext,
            cart_column text,           -- Cart column number (1, 2, 3, or 4)
            cart_id int NULL,
            cart_config_id int NULL,
            locked citext NULL
        );

        INSERT INTO Tmp_BlockingInfo ( request_id, cart_name, cart_config_name, cart_column)
        SELECT XmlQ.request_id, Trim(XmlQ.cart), Trim(XmlQ.cart_config), Trim(XmlQ.cart_column)
        FROM (
            SELECT xmltable.*
            FROM ( SELECT _xml AS rooted_xml
                 ) Src,
                 XMLTABLE('//root/r'
                          PASSING Src.rooted_xml
                          COLUMNS request_id  int  PATH '@rq',
                                  cart        text PATH '@ct',
                                  cart_config text PATH '@cg',
                                  cart_column text PATH '@co')
             ) XmlQ;
        --
        GET DIAGNOSTICS _requestCountInXML = ROW_COUNT;

        If _requestCountInXML = 0 Then
            _message := 'No requested runs were found in the XML';

            RAISE WARNING '%', _message;
            _returnCode := 'U5201';

            DROP TABLE Tmp_BlockingInfo;
            RETURN;
        End If;

        UPDATE Tmp_BlockingInfo
        SET cart_config_name = ''
        WHERE cart_config_name IS NULL;

        -----------------------------------------------------------
        -- Resolve cart name to cart ID
        -----------------------------------------------------------

        UPDATE Tmp_BlockingInfo
        SET cart_id = t_lc_cart.cart_id
        FROM t_lc_cart
        WHERE Tmp_BlockingInfo.cart_name = t_lc_cart.cart_name;

        If Exists (SELECT request_id FROM Tmp_BlockingInfo WHERE cart_id IS NULL) Then

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

            RAISE WARNING '%', _message;
            _returnCode := 'U5202';

            DROP TABLE Tmp_BlockingInfo;
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Resolve cart config name to cart config ID
        -----------------------------------------------------------

        UPDATE Tmp_BlockingInfo
        SET cart_config_id = CartConfig.cart_config_id
        FROM t_lc_cart_configuration AS CartConfig
        WHERE Tmp_BlockingInfo.cart_config_name = CartConfig.cart_config_name;

        If Exists (SELECT request_id FROM Tmp_BlockingInfo WHERE cart_config_name <> '' AND cart_config_id IS NULL) Then

            SELECT cart_config_name
            INTO _invalidCartConfig
            FROM Tmp_BlockingInfo
            WHERE cart_config_name <> '' AND cart_config_id IS NULL
            LIMIT 1;

            _message := format('Invalid cart config name: %s', _invalidCartConfig);

            RAISE WARNING '%', _message;
            _returnCode := 'U5203';

            DROP TABLE Tmp_BlockingInfo;
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Batch info
        -----------------------------------------------------------

        UPDATE Tmp_BlockingInfo
        SET locked = RRB.Locked
        FROM t_requested_run RR
             INNER JOIN t_requested_run_batches AS RRB
               ON RR.batch_id = RRB.batch_id
        WHERE Tmp_BlockingInfo.request_id = RR.request_id;

        -----------------------------------------------------------
        -- Check for locked batches
        -----------------------------------------------------------

        If Exists (SELECT request_id FROM Tmp_BlockingInfo WHERE locked = 'Yes') Then

            SELECT MIN(request_id),
                   MAX(request_id)
            INTO _firstLocked, _lastLocked
            FROM Tmp_BlockingInfo
            WHERE locked = 'Yes';

            If _firstLocked = _lastLocked Then
                _message := format('Cannot change requests in locked batches; request %s is locked', _firstLocked);
            Else
                _message := format('Cannot change requests in locked batches; locked requests include %s and %s', _firstLocked, _lastLocked);
            End If;

            RAISE WARNING '%', _message;
            _returnCode := 'U5204';

            DROP TABLE Tmp_BlockingInfo;
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Disregard unchanged requests
        -----------------------------------------------------------

        DELETE FROM Tmp_BlockingInfo
        WHERE request_id IN ( SELECT BI.request_id
                              FROM Tmp_BlockingInfo BI
                                   INNER JOIN t_requested_run AS RR
                                     ON BI.request_id                      = RR.request_id AND
                                        BI.cart_id                         = RR.cart_id AND
                                        Coalesce(BI.cart_config_id, 0)     = Coalesce(RR.cart_config_id, 0) AND
                                        public.try_cast(BI.cart_column, 0) = Coalesce(RR.cart_column, 0)
                            );
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        If _debugMode Then
            If _requestCountInXML = _deleteCount Then
                If _requestCountInXML = 1 Then
                    _debugMsg := 'The request was unchanged; nothing to do';
                Else
                    _debugMsg := format('All %s requests were unchanged; nothing to do', _requestCountInXML);
                End If;
            ElsIf _deleteCount = 0 Then
                _debugMsg := format('Will update all %s requests', _requestCountInXML);
            Else
                _debugMsg := format('Will update %s of %s requests', _requestCountInXML - _deleteCount, _requestCountInXML);
            End If;

            RAISE INFO '%', _debugMsg;

            CALL post_log_entry ('Debug', _debugMsg, 'Update_LC_Cart_Request_Assignments');
        End If;

        -----------------------------------------------------------
        -- Update requested runs
        -----------------------------------------------------------

        UPDATE t_requested_run
        SET cart_id        = BI.cart_id,
            cart_config_id = BI.cart_config_id,
            cart_column    = public.try_cast(BI.cart_column, 0)
        FROM Tmp_BlockingInfo BI
        WHERE BI.request_id = t_requested_run.request_id;
        --
        GET DIAGNOSTICS _updateRowCount = ROW_COUNT;

        _message := format('Updated %s requested %s', _updateRowCount, public.check_plural(_updateRowCount, 'run', 'runs'));
        RAISE INFO '%', _message;

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

    _usageMessage := format('%s requested %s updated', _updateRowCount, public.check_plural(_updateRowCount, 'run', 'runs'));
    CALL post_usage_log_entry ('update_lc_cart_request_assignments', _usageMessage);

    DROP TABLE IF EXISTS Tmp_BlockingInfo;
END
$$;


ALTER PROCEDURE public.update_lc_cart_request_assignments(IN _cartassignmentlist text, IN _mode text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_lc_cart_request_assignments(IN _cartassignmentlist text, IN _mode text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_lc_cart_request_assignments(IN _cartassignmentlist text, IN _mode text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateLCCartRequestAssignments';

