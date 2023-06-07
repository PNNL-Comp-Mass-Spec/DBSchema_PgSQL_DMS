--
CREATE OR REPLACE PROCEDURE public.update_requested_run_batch_parameters
(
    _blockingList text,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Change run blocking parameters given by lists
**
**      Example XML for _blockingList
**        <r i="481295" t="Run_Order" v="1" />
**        <r i="481295" t="Block" v="2" />
**        <r i="481296" t="Run_Order" v="1" />
**        <r i="481296" t="Block" v="1" />
**        <r i="481297" t="Run_Order" v="2" />
**        <r i="481297" t="Block" v="1" />
**
**      Valid values for type (t) are:
**        'BK', 'RO', 'Block', 'Run_Order', 'Run Order', 'Status', 'Instrument', or 'Cart'
**
**  Arguments:
**    _blockingList   XML (see above)
**    _mode           'update'
**
**  Auth:   grk
**  Date:   02/09/2010
**          02/16/2010 grk - Eliminated batchID from arg list
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          12/15/2011 mem - Now updating _callingUser to session_user if empty
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _xml AS XML;
    _batchID int := 0;
    _debugEnabled boolean := false;
    _logMessage text;
    _misnamedCarts text := '';
    _minBatchID int := 0;
    _maxBatchID int := 0;
    _requestedRunList text := null;
    _requestID int := -100000;
    _changeSummary text := '';
    _usageMessage text := '';
    _requestIdFirst int;
    _requestIdLast int;
    _msg text;

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
    -- Validate the inputs
    -----------------------------------------------------------

    If Coalesce(_callingUser, '') = '' Then
        _callingUser := get_user_login_without_domain('');
    End If;

    -- Set to true to log the contents of _blockingList

    If _debugEnabled Then
        _logMessage := _blockingList;

        CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_Batch_Parameters');
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    BEGIN
        -----------------------------------------------------------
        -- Temp table to hold new parameters
        -----------------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_NewBatchParams (
            Parameter citext,
            request_id int,
            Value text,
            ExistingValue text NULL
        )

        If _mode = 'update' OR _mode = 'debug' Then
            -----------------------------------------------------------
            -- Convert _blockingList to rooted XML
            -----------------------------------------------------------

            _xml := public.try_cast('<root>' || _blockingList || '</root>', null::xml);

            If _xml Is Null Then
                _message := 'Blocking list is not valid XML';
                RAISE EXCEPTION '%', _message;
            End If;

            -----------------------------------------------------------
            -- Populate temp table with new parameters
            -----------------------------------------------------------
            --
            INSERT INTO Tmp_NewBatchParams ( Parameter, request_id, Value )
            SELECT XmlQ.Parameter, XmlQ.RequestID, XmlQ.Value
            FROM (
                SELECT xmltable.*
                FROM ( SELECT _xml As rooted_xml
                     ) Src,
                     XMLTABLE('//root/r'
                              PASSING Src.rooted_xml
                              COLUMNS Parameter citext PATH '@t',   -- Valid values are 'BK', 'RO', 'Block', 'Run_Order', 'Run Order', 'Status', 'Instrument', or 'Cart'
                                      RequestID int PATH '@i',
                                      Value citext PATH '@v')
                 ) XmlQ;

            -----------------------------------------------------------
            -- Normalize parameter names
            -----------------------------------------------------------
            --
            UPDATE Tmp_NewBatchParams SET Parameter = 'Block'     WHERE Parameter = 'BK';
            UPDATE Tmp_NewBatchParams SET Parameter = 'Run Order' WHERE Parameter = 'RO';
            UPDATE Tmp_NewBatchParams SET Parameter = 'Run Order' WHERE Parameter = 'Run_Order';

            If _mode = 'debug' Then
                -- ToDo: convert to RAISE INFO
                SELECT * FROM Tmp_NewBatchParams
            End If;

            -----------------------------------------------------------
            -- Store current values in the temp table
            -----------------------------------------------------------
            --
            UPDATE Tmp_NewBatchParams
            SET ExistingValue = CASE
                                    WHEN Tmp_NewBatchParams.Parameter = 'Block'      THEN Cast(block As Text)
                                    WHEN Tmp_NewBatchParams.Parameter = 'Run Order'  THEN Cast(run_order As text)
                                    WHEN Tmp_NewBatchParams.Parameter = 'Status'     THEN state_name
                                    WHEN Tmp_NewBatchParams.Parameter = 'Instrument' THEN instrument_group
                                    ELSE ''
                                END
            FROM t_requested_run
            WHERE Tmp_NewBatchParams.request_id = t_requested_run.request_id;

            -- Store the current cart name
            UPDATE Tmp_NewBatchParams
            SET ExistingValue = t_lc_cart.cart_name
            FROM t_requested_run
                   ON Tmp_NewBatchParams.request_id = t_requested_run.request_id
                 INNER JOIN t_lc_cart
                   ON t_requested_run.cart_id = t_lc_cart.cart_id
            WHERE Tmp_NewBatchParams.Parameter = 'Cart'

            If _mode = 'debug' Then
                SELECT * FROM Tmp_NewBatchParams
            End If;

            -----------------------------------------------------------
            -- Remove entries that are unchanged
            -----------------------------------------------------------
            --
            DELETE FROM Tmp_NewBatchParams
            WHERE Tmp_NewBatchParams.Value = Tmp_NewBatchParams.ExistingValue;

            -----------------------------------------------------------
            -- Validate
            -----------------------------------------------------------

            SELECT string_agg(Tmp_NewBatchParams.Value, ', ' ORDER BY Tmp_NewBatchParams.Value)
            INTO _misnamedCarts
            FROM Tmp_NewBatchParams
            WHERE Tmp_NewBatchParams.Parameter = 'Cart' AND
                  NOT (Tmp_NewBatchParams.Value IN ( SELECT cart_name FROM t_lc_cart ))

            If Coalesce(_misnamedCarts, '') <> '' Then
                RAISE EXCEPTION 'Cart(s) % are incorrect', _misnamedCarts;
            End If;

        End If;

        If _mode = 'debug' Then
            -- ToDo: convert to RAISE INFO
            SELECT * FROM Tmp_NewBatchParams
        End If;

        -----------------------------------------------------------
        -- Is there anything left to update?
        -----------------------------------------------------------
        --
        If Not Exists (SELECT * FROM Tmp_NewBatchParams) Then
            _message := 'No run parameters to update';
            DROP TABLE Tmp_NewBatchParams;
            RETURN;
        End If;

        -----------------------------------------------------------
        -- Actually do the update
        -----------------------------------------------------------
        --
        If _mode = 'update' Then
            BEGIN
                UPDATE t_requested_run
                SET block = Tmp_NewBatchParams.Value
                FROM Tmp_NewBatchParams
                WHERE Tmp_NewBatchParams.Parameter = 'block' AND
                      Tmp_NewBatchParams.request_id = t_requested_run.request_id;

                UPDATE t_requested_run
                SET run_order = Tmp_NewBatchParams.Value
                FROM Tmp_NewBatchParams
                WHERE Tmp_NewBatchParams.Parameter = 'Run Order' AND
                      Tmp_NewBatchParams.request_id = t_requested_run.request_id;

                UPDATE t_requested_run
                SET state_name = Tmp_NewBatchParams.Value
                FROM Tmp_NewBatchParams
                WHERE Tmp_NewBatchParams.Parameter = 'Status' AND
                      Tmp_NewBatchParams.request_id = t_requested_run.request_id;

                UPDATE t_requested_run
                SET cart_id = t_lc_cart.cart_id
                FROM Tmp_NewBatchParams
                     INNER JOIN t_lc_cart
                       ON Tmp_NewBatchParams.Value = t_lc_cart.cart_name
                WHERE Tmp_NewBatchParams.Parameter = 'Cart' AND
                      Tmp_NewBatchParams.request_id = t_requested_run.request_id;

                UPDATE t_requested_run
                SET instrument_group = Tmp_NewBatchParams.Value
                FROM Tmp_NewBatchParams
                WHERE Tmp_NewBatchParams.Parameter = 'Instrument' AND
                      Tmp_NewBatchParams.request_id = t_requested_run.request_id;

            END;

        End If;

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

    If _mode = 'update' Then

        -- Commit the changes, then call update_cached_requested_run_batch_stats and update_cached_requested_run_eus_users
        --
        COMMIT;

        BEGIN

            If Exists (SELECT * FROM Tmp_NewBatchParams WHERE Parameter = 'Run Order') Then
                -- If all of the updated requests come from the same batch,
                -- update last_ordered in t_requested_run_batches

                SELECT MIN(batch_id),
                       MAX(batch_id)
                INTO _minBatchID, _maxBatchID
                FROM Tmp_NewBatchParams Src
                     INNER JOIN t_requested_run RR
                       ON Src.request_id = RR.request_id;

                If (_minBatchID > 0 Or _maxBatchID > 0) Then
                    If _minBatchID = _maxBatchID Then
                        UPDATE t_requested_run_batches
                        SET last_ordered = CURRENT_TIMESTAMP
                        WHERE batch_id = _minBatchID;
                    Else

                        SELECT string_agg(Request::text, ', ' ORDER BY Request)
                        INTO _requestedRunList
                        FROM Tmp_NewBatchParams;

                        _logMessage := format('Requested runs do not all belong to the same batch: %s vs. %s; see requested runs %s',
                                            _minBatchID, _maxBatchID, _requestedRunList);

                        CALL post_log_entry ('Warning', _logMessage, 'Update_Requested_Run_Batch_Parameters');
                    End If;

                    -- Update cached data in T_Cached_Requested_Run_Batch_Stats
                    CALL update_cached_requested_run_batch_stats (
                        _minBatchID,
                        _message => _msg,               -- Output
                        _returnCode => _returnCode);    -- Output

                    If _returnCode <> '' Then
                        _message := public.append_to_text(_message, _msg, 0, '; ', 512);
                    End If;

                    If _maxBatchID <> _minBatchID Then
                        CALL update_cached_requested_run_batch_stats (
                            _maxBatchID,
                            _message => _msg,               -- Output
                            _returnCode => _returnCode);    -- Output

                        If _returnCode <> '' Then
                            _message := public.append_to_text(_message, _msg, 0, '; ', 512);
                        End If;
                    End If;

                End If;
            End If;

            If Exists (SELECT * FROM Tmp_NewBatchParams WHERE Parameter = 'Status') Then
                -- Call update_cached_requested_run_eus_users for each entry in Tmp_NewBatchParams
                --

                FOR _requestID IN
                    SELECT request_id
                    FROM Tmp_NewBatchParams
                    WHERE Parameter = 'Status'
                    ORDER BY request_id
                LOOP
                    CALL update_cached_requested_run_eus_users (
                            _requestID,
                            _message => _message,           -- Output
                            _returnCode => _returnCode);    -- Output
                END LOOP;
            End If;

            -----------------------------------------------------------
            -- Convert changed items to XML for logging
            -----------------------------------------------------------
            --
            SELECT string_agg(format('<r i="%s" t="%s" v="%s" />', Request, Parameter, Value), '' ORDER BY Request)
            INTO _changeSummary
            FROM Tmp_NewBatchParams;

            -----------------------------------------------------------
            -- Log changes
            -----------------------------------------------------------
            --
            If _changeSummary <> '' Then
                INSERT INTO t_factor_log (changed_by, changes)
                VALUES (_callingUser, _changeSummary);
            End If;

            ---------------------------------------------------
            -- Log SP usage
            ---------------------------------------------------

            SELECT MIN(Request),
                   MAX(Request)
            INTO _requestIdFirst, _requestIdLast
            FROM Tmp_NewBatchParams;

            If _requestIdFirst Is Null Then
                _usageMessage := 'Request IDs: not defined';
            Else
                If _requestIdFirst = _requestIdLast then
                    _usageMessage := format('Request ID: '%s, _requestIdFirst);
                Else
                    _usageMessage := format('Request IDs: %s - %s', _requestIdFirst, _requestIdLast);
                End If;
            End If;

            CALL post_usage_log_entry ('Update_Requested_Run_Batch_Parameters', _usageMessage);

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

    End If;

    DROP TABLE IF EXISTS Tmp_NewBatchParams;
END
$$;

COMMENT ON PROCEDURE public.update_requested_run_batch_parameters IS 'UpdateRequestedRunBatchParameters';
