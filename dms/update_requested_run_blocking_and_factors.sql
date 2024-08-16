--
-- Name: update_requested_run_blocking_and_factors(text, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_requested_run_blocking_and_factors(IN _blockinglist text, IN _factorlist text, IN _debugmode boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update requested run factors and blocking using the specified XML
**
**      Called from https://dms2.pnl.gov/requested_run_batch_blocking/param
**
**      Example contents of _blockingList:
**        <r i="400213" t="Run_Order" v="12" /><r i="400213" t="Block" v="3" />
**        <r i="400214" t="Run_Order" v="1" /> <r i="400214" t="Block" v="3" />
**
**      Example contents of _factorList:
**        <id type="Request" /><r i="400213" f="TempFactor" v="a" /><r i="400214" f="TempFactor" v="b" />
**
**  Arguments:
**    _blockingList     Block and run order info, as XML (see above); can be empty if _factorList is defined
**    _factorList       Factor names and values, as XML (see above); can be '<id type="Request" />' if updating run order and blocking
**    _debugMode        When true, log the contents of _blockingList and _factorList in t_log_entries
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   02/21/2010
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          11/07/2016 mem - Add optional logging via post_log_entry
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/04/2019 mem - Tabs to spaces
**          12/13/2022 mem - Log procedure usage even if UpdateRequestedRunBatchParameters returns a non-zero return code
**          03/06/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _xml xml;
    _logMessage text;
    _usageMessage text := '';
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

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _blockingList := Trim(Coalesce(_blockingList, ''));
    _factorList   := Trim(Coalesce(_factorList, ''));
    _debugMode    := Coalesce(_debugMode, false);
    _callingUser  := Trim(Coalesce(_callingUser, ''));

    -- Uncomment to turn on debug mode
    -- _debugMode := true;

    If _debugMode Then
        If _blockingList = '' Then
            _logMessage := '_blockingList is empty';
        Else
            _logMessage := format('Blocking list: %s', _blockingList);
        End If;

        CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_Blocking_And_Factors');

        If _factorList = '' Then
            _logMessage := '_factorList is empty';
        Else
            _logMessage := format('Factor list: %s', _factorList);
        End If;

        CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_Blocking_And_Factors');
    End If;

    -----------------------------------------------------------
    -- Update the blocking and run order
    -----------------------------------------------------------

    If _blockingList <> '' Then
        CALL public.update_requested_run_batch_parameters (
                        _blockingList => _blockingList,
                        _mode         => 'update',
                        _debugMode    => false,          -- Set this to false even if _debugMode is true, since the XML has already been logged
                        _message      => _message,       -- Output
                        _returnCode   => _returnCode,    -- Output
                        _callingUser  => _callingUser);

    End If;

    -----------------------------------------------------------
    -- Update the factors (if an empty return code)
    -----------------------------------------------------------

    If _returnCode = '' Then
        CALL public.update_requested_run_factors (
                                _factorList  => _factorList,
                                _infoOnly    => false,
                                _message     => _message,       -- Output
                                _returnCode  => _returnCode,    -- Output
                                _callingUser => _callingUser);
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := '';
    CALL post_usage_log_entry ('update_requested_run_blocking_and_factors', _usageMessage);

END
$$;


ALTER PROCEDURE public.update_requested_run_blocking_and_factors(IN _blockinglist text, IN _factorlist text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_requested_run_blocking_and_factors(IN _blockinglist text, IN _factorlist text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_requested_run_blocking_and_factors(IN _blockinglist text, IN _factorlist text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateRequestedRunBlockingAndFactors';

