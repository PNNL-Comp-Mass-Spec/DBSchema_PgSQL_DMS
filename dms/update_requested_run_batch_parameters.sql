--
-- Name: update_requested_run_batch_parameters(text, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_requested_run_batch_parameters(IN _blockinglist text, IN _mode text, IN _debugmode boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update requested run blocking parameters using the specified XML
**
**      Example XML for _blockingList
**        <r i="400213" t="Run_Order" v="12" />
**        <r i="400213" t="Block" v="3" />
**        <r i="400214" t="Run_Order" v="1" />
**        <r i="400214" t="Block" v="3" />
**        <r i="400215" t="Run_Order" v="7" />
**        <r i="400215" t="Block" v="3" />
**        <r i="400213" t="Status"     v="Active" />
**        <r i="400213" t="Instrument" v="VelosOrbi" />
**        <r i="400213" t="Cart"       v="Tiger" />
**
**      Valid values for type (t):
**        'BK' or 'Block'                    Blocking group
**        'RO','Run_Order', or 'Run Order'   Run order
**        'Status'                           Requested Run State Name
**        'Instrument'                       Instrument group
**        'Cart'                             Cart name
**
**  Arguments:
**    _blockingList     Block and run order info, as XML (see above)
**    _mode             Mode: 'update', 'preview', 'debug'; 'debug' and 'preview' (identical modes) can be used to preview updates
**    _debugMode        When true, log the contents of _blockingList in t_log_entries
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   02/09/2010
**          02/16/2010 grk - Eliminated batchID from arg list
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          12/15/2011 mem - Now updating _callingUser to SESSION_USER if empty
**          03/28/2013 grk - Added handling for cart, instrument
**          11/07/2016 mem - Add optional logging via post_log_entry
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          11/16/2016 mem - Call update_cached_requested_run_eus_users for updated Requested runs
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/04/2019 mem - Update Last_Ordered if the run order changes
**          10/19/2020 mem - Rename the instrument group column to instrument_group
**          01/24/2023 mem - Recognize 'Run_Order' for run order
**          02/11/2023 mem - Update the usage message sent to Post_Usage_Log_Entry
**          03/10/2023 mem - Call update_cached_requested_run_batch_stats to update T_Cached_Requested_Run_Batch_Stats
**          03/06/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := true;
    _blockingXML xml;
    _batchID int := 0;
    _logMessage text;
    _misnamedCarts text := '';
    _requestCountToUpdate int;
    _minBatchID int := 0;
    _maxBatchID int := 0;
    _requestedRunList text := null;
    _requestID int := -100000;
    _changeSummary text := '';
    _usageMessage text := '';
    _requestIdFirst int;
    _requestIdLast int;
    _msg text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

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

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _blockingList := Trim(Coalesce(_blockingList, ''));
    _mode         := Trim(Lower(Coalesce(_mode, '')));
    _debugMode    := Coalesce(_debugMode, false);
    _callingUser  := Trim(Coalesce(_callingUser, ''));

    If _callingUser = '' Then
        _callingUser := public.get_user_login_without_domain('');
    End If;

    If Not _mode In ('update', 'preview', 'debug') Then
        _message := format('Supported modes are "update" or "debug", not "%s"', _mode);
        RAISE WARNING '%', _message;
    End If;

    If _mode = 'debug' Then
        _mode := 'preview';
    End If;

    If _debugMode Then
        _logMessage := _blockingList;

        CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_Batch_Parameters');
    End If;

    BEGIN
        -----------------------------------------------------------
        -- Temp table to hold new parameters
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_NewBatchParams (
            Parameter citext,
            Request_ID int,
            Value text,
            Existing_Value text NULL
        );

        _formatSpecifier := '%-10s %-10s %-15s %-15s';

        _infoHead := format(_formatSpecifier,
                            'Parameter',
                            'Request_ID',
                            'Value',
                            'Existing_Value'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----------',
                                     '---------------',
                                     '---------------'
                                    );

        -----------------------------------------------------------
        -- Convert _blockingList to rooted XML
        -----------------------------------------------------------

        _blockingXML := public.try_cast('<root>' || _blockingList || '</root>', null::xml);

        If _blockingXML Is Null Then
            _logErrors := false;
            _message := 'Blocking list is not valid XML';
            RAISE WARNING '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        -----------------------------------------------------------
        -- Populate temp table with new parameters
        -----------------------------------------------------------

        INSERT INTO Tmp_NewBatchParams (Parameter, Request_ID, Value)
        SELECT Trim(XmlQ.Parameter), XmlQ.RequestID, Trim(XmlQ.Value)
        FROM (
            SELECT xmltable.*
            FROM ( SELECT _blockingXML AS rooted_xml
                 ) Src,
                 XMLTABLE('//root/r'
                          PASSING Src.rooted_xml
                          COLUMNS Parameter text PATH '@t',   -- Valid values are 'BK', 'RO', 'Block', 'Run_Order', 'Run Order', 'Status', 'Instrument', or 'Cart'
                                  RequestID int  PATH '@i',
                                  Value     text PATH '@v')
             ) XmlQ;

        -----------------------------------------------------------
        -- Normalize parameter names
        -----------------------------------------------------------

        UPDATE Tmp_NewBatchParams SET Parameter = 'Block'     WHERE Parameter = 'BK';
        UPDATE Tmp_NewBatchParams SET Parameter = 'Run Order' WHERE Parameter = 'RO';
        UPDATE Tmp_NewBatchParams SET Parameter = 'Run Order' WHERE Parameter = 'Run_Order';

        If _mode = 'preview' Then
            RAISE INFO '';
            RAISE INFO 'Contents of Tmp_NewBatchParams after switching from BK to Block, and RO to "Run Order"';
            RAISE INFO '';
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Parameter,
                       Request_ID,
                       Value,
                       Existing_Value
                FROM Tmp_NewBatchParams
                ORDER BY Request_ID, Parameter
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Parameter,
                                    _previewData.Request_ID,
                                    _previewData.Value,
                                    _previewData.Existing_Value
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;
        End If;

        -----------------------------------------------------------
        -- Store current values in the temp table
        -----------------------------------------------------------

        UPDATE Tmp_NewBatchParams
        SET Existing_Value = CASE
                                 WHEN Tmp_NewBatchParams.Parameter = 'Block'      THEN block::text
                                 WHEN Tmp_NewBatchParams.Parameter = 'Run Order'  THEN run_order::text
                                 WHEN Tmp_NewBatchParams.Parameter = 'Status'     THEN state_name
                                 WHEN Tmp_NewBatchParams.Parameter = 'Instrument' THEN instrument_group
                                 ELSE ''
                             END
        FROM t_requested_run
        WHERE Tmp_NewBatchParams.Request_ID = t_requested_run.request_id;

        -- Store the current cart name
        UPDATE Tmp_NewBatchParams
        SET Existing_Value = t_lc_cart.cart_name
        FROM t_requested_run
             INNER JOIN t_lc_cart
               ON t_requested_run.cart_id = t_lc_cart.cart_id
        WHERE Tmp_NewBatchParams.Parameter = 'Cart' AND
              Tmp_NewBatchParams.Request_ID = t_requested_run.request_id;

        If _mode = 'preview' Then
            RAISE INFO '';
            RAISE INFO 'Contents of Tmp_NewBatchParams after populating Existing_Value';
            RAISE INFO '';

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Parameter,
                       Request_ID,
                       Value,
                       Existing_Value
                FROM Tmp_NewBatchParams
                ORDER BY Request_ID, Parameter
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Parameter,
                                    _previewData.Request_ID,
                                    _previewData.Value,
                                    _previewData.Existing_Value
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;
        End If;

        -----------------------------------------------------------
        -- Remove entries that are unchanged
        -----------------------------------------------------------

        DELETE FROM Tmp_NewBatchParams
        WHERE Value = Existing_Value;

        -----------------------------------------------------------
        -- Validate
        -----------------------------------------------------------

        SELECT string_agg(Tmp_NewBatchParams.Value, ', ' ORDER BY Tmp_NewBatchParams.Value)
        INTO _misnamedCarts
        FROM Tmp_NewBatchParams
        WHERE Tmp_NewBatchParams.Parameter = 'Cart' AND
              NOT Tmp_NewBatchParams.Value IN (SELECT cart_name FROM t_lc_cart);

        If Coalesce(_misnamedCarts, '') <> '' Then
            If Position(',' In _misnamedCarts) > 0 Then
                _message := format('Invalid cart names: %s', _misnamedCarts);
            Else
                _message := format('Invalid cart name: %s', _misnamedCarts);
            End If;

            _logErrors := false;
            RAISE WARNING '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        If _mode = 'preview' Then
            RAISE INFO '';
            RAISE INFO 'Contents of Tmp_NewBatchParams after removing entries that are already up-to-date';
            RAISE INFO '';

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Parameter,
                       Request_ID,
                       Value,
                       Existing_Value
                FROM Tmp_NewBatchParams
                ORDER BY Request_ID, Parameter
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Parameter,
                                    _previewData.Request_ID,
                                    _previewData.Value,
                                    _previewData.Existing_Value
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;
        End If;

        -----------------------------------------------------------
        -- Is there anything left to update?
        -----------------------------------------------------------

        SELECT COUNT(*)
        INTO _requestCountToUpdate
        FROM Tmp_NewBatchParams;

        If Coalesce(_requestCountToUpdate, 0) = 0 Then
            _message := 'Requested run blocking parameters are already up-to-date';
            RAISE INFO '%', _message;

            DROP TABLE Tmp_NewBatchParams;
            RETURN;
        End If;

        If _mode <> 'update' Then
            DROP TABLE Tmp_NewBatchParams;
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Actually do the update
        -----------------------------------------------------------

        UPDATE t_requested_run
        SET block = public.try_cast(Tmp_NewBatchParams.Value, block)
        FROM Tmp_NewBatchParams
        WHERE Tmp_NewBatchParams.Parameter = 'Block' AND
              Tmp_NewBatchParams.Request_ID = t_requested_run.request_id;

        UPDATE t_requested_run
        SET run_order = public.try_cast(Tmp_NewBatchParams.Value, run_order)
        FROM Tmp_NewBatchParams
        WHERE Tmp_NewBatchParams.Parameter = 'Run Order' AND
              Tmp_NewBatchParams.Request_ID = t_requested_run.request_id;

        UPDATE t_requested_run
        SET state_name = Tmp_NewBatchParams.Value
        FROM Tmp_NewBatchParams
        WHERE Tmp_NewBatchParams.Parameter = 'Status' AND
              Tmp_NewBatchParams.Request_ID = t_requested_run.request_id;

        UPDATE t_requested_run
        SET cart_id = t_lc_cart.cart_id
        FROM Tmp_NewBatchParams
             INNER JOIN t_lc_cart
               ON Tmp_NewBatchParams.Value = t_lc_cart.cart_name
        WHERE Tmp_NewBatchParams.Parameter = 'Cart' AND
              Tmp_NewBatchParams.Request_ID = t_requested_run.request_id;

        UPDATE t_requested_run
        SET instrument_group = Tmp_NewBatchParams.Value
        FROM Tmp_NewBatchParams
        WHERE Tmp_NewBatchParams.Parameter = 'Instrument' AND
              Tmp_NewBatchParams.Request_ID = t_requested_run.request_id;

        If Exists (SELECT Parameter FROM Tmp_NewBatchParams WHERE Parameter = 'Run Order') Then
            -----------------------------------------------------------
            -- Call update_cached_requested_run_batch_stats and update_cached_requested_run_eus_users
            -----------------------------------------------------------

            -- If all of the updated requests come from the same batch, update last_ordered in t_requested_run_batches

            SELECT MIN(batch_id),
                   MAX(batch_id)
            INTO _minBatchID, _maxBatchID
            FROM Tmp_NewBatchParams Src
                 INNER JOIN t_requested_run RR
                   ON Src.Request_ID = RR.request_id;

            If _minBatchID > 0 Or _maxBatchID > 0 Then
                If _minBatchID = _maxBatchID Then
                    UPDATE t_requested_run_batches
                    SET last_ordered = CURRENT_TIMESTAMP
                    WHERE batch_id = _minBatchID;
                Else
                    SELECT string_agg(Request_ID::text, ', ' ORDER BY Request_ID)
                    INTO _requestedRunList
                    FROM Tmp_NewBatchParams;

                    _logMessage := format('Requested runs do not all belong to the same batch: %s vs. %s; see requested runs %s',
                                          _minBatchID, _maxBatchID, _requestedRunList);

                    CALL post_log_entry ('Warning', _logMessage, 'Update_Requested_Run_Batch_Parameters');
                End If;

                -- Update cached data in T_Cached_Requested_Run_Batch_Stats
                CALL public.update_cached_requested_run_batch_stats (
                                    _batchID     => _minBatchID,
                                    _fullRefresh => false,
                                    _message     => _msg,               -- Output
                                    _returnCode  => _returnCode);       -- Output

                If _returnCode <> '' Then
                    _message := public.append_to_text(_message, _msg);
                End If;

                If _maxBatchID <> _minBatchID Then
                    CALL public.update_cached_requested_run_batch_stats (
                                    _batchID     => _maxBatchID,
                                    _fullRefresh => false,
                                    _message     => _msg,               -- Output
                                    _returnCode  => _returnCode);       -- Output

                    If _returnCode <> '' Then
                        _message := public.append_to_text(_message, _msg);
                    End If;
                End If;

            End If;
        End If;

        If Exists (SELECT Parameter FROM Tmp_NewBatchParams WHERE Parameter = 'Status') Then
            -----------------------------------------------------------
            -- Call update_cached_requested_run_eus_users for each entry in Tmp_NewBatchParams
            -----------------------------------------------------------

            FOR _requestID IN
                SELECT request_id
                FROM Tmp_NewBatchParams
                WHERE Parameter = 'Status'
                ORDER BY request_id
            LOOP
                CALL public.update_cached_requested_run_eus_users (
                                _requestID  => _requestID,
                                _message    => _msg,            -- Output
                                _returnCode => _returnCode);    -- Output
            END LOOP;
        End If;

        _msg := format('Updated %s requested %s', _requestCountToUpdate, public.check_plural(_requestCountToUpdate, 'run', 'runs'));
        RAISE INFO '%', _msg;

        _message := public.append_to_text(_message, _msg);

        -----------------------------------------------------------
        -- Convert changed items to XML for logging
        -----------------------------------------------------------

        SELECT string_agg(format('<r i="%s" t="%s" v="%s" />', Request_ID, Parameter, Value), '' ORDER BY Request_ID)
        INTO _changeSummary
        FROM Tmp_NewBatchParams;

        -----------------------------------------------------------
        -- Log changes
        -----------------------------------------------------------

        If _changeSummary <> '' Then
            INSERT INTO t_factor_log (changed_by, changes)
            VALUES (_callingUser, _changeSummary);
        End If;

        ---------------------------------------------------
        -- Log SP usage
        ---------------------------------------------------

        SELECT MIN(Request_ID),
               MAX(Request_ID)
        INTO _requestIdFirst, _requestIdLast
        FROM Tmp_NewBatchParams;

        If _requestIdFirst Is Null Then
            _usageMessage := 'Requested run IDs: not defined';
        Else
            If _requestIdFirst = _requestIdLast then
                _usageMessage := format('Requested run ID: %s', _requestIdFirst);
            Else
                _usageMessage := format('Requested run IDs: %s - %s', _requestIdFirst, _requestIdLast);
            End If;
        End If;

        CALL post_usage_log_entry ('update_requested_run_batch_parameters', _usageMessage);

        DROP TABLE Tmp_NewBatchParams;
        RETURN;

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

    DROP TABLE IF EXISTS Tmp_NewBatchParams;
END
$$;


ALTER PROCEDURE public.update_requested_run_batch_parameters(IN _blockinglist text, IN _mode text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_requested_run_batch_parameters(IN _blockinglist text, IN _mode text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_requested_run_batch_parameters(IN _blockinglist text, IN _mode text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateRequestedRunBatchParameters';

