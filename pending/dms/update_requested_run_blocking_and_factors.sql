--
CREATE OR REPLACE PROCEDURE public.update_requested_run_blocking_and_factors
(
    _blockingList text,
    _factorList text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update requested run factors and blocking from input XML lists
**      Called from https://dms2.pnl.gov/requested_run_batch_blocking/param
**
**      Example contents of _blockingList:
**        <r i="545496" t="Run_Order" v="2" /><r i="545496" t="Block" v="2" />
**        <r i="545497" t="Run_Order" v="1" /><r i="545497" t="Block" v="1" />
**
**      Example contents of _factorList:
**        <id type="Request" /><r i="545496" f="TempFactor" v="a" /><r i="545497" f="TempFactor" v="b" />
**
**      _blockingList can be empty if _factorList is defined
**      Conversely, _factorList may be simply '<id type="Request" />' if updating run order and blocking
**
**  Auth:   grk
**  Date:   02/21/2010
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          11/07/2016 mem - Add optional logging via PostLogEntry
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/04/2019 mem - Tabs to spaces
**          12/13/2022 mem - Log procedure usage even if UpdateRequestedRunBatchParameters returns a non-zero return code
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _xml AS xml;
    _debugEnabled boolean := false;
    _logMessage text;
    _usageMessage text := '';
BEGIN
    _message := '';
    _returnCode := '';

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

    If _debugEnabled Then

        _logMessage := Cast(_blockingList as text);
        If Coalesce(_logMessage, '') = '' Then
            _logMessage := '_blockingList is empty';
        Else
            _logMessage := '_blockingList: ' || _logMessage;
        End If;

        Call post_log_entry ('Debug', _logMessage, 'UpdateRequestedRunBlockingAndFactors');

        _logMessage := Cast(_factorList as text);
        If Coalesce(_logMessage, '') = '' Then
            _logMessage := '_factorList is empty';
        Else
            _logMessage := '_factorList: ' || _logMessage;
        End If;

        Call post_log_entry ('Debug', _logMessage, 'UpdateRequestedRunBlockingAndFactors');
    End If;

    -----------------------------------------------------------
    -- Update the blocking and run order
    -----------------------------------------------------------
    --
    If char_length(_blockingList) > 0 Then
        Call update_requested_run_batch_parameters (
                            _blockingList,
                            'update',
                            _message => _message,           -- Output
                            _returnCode => _returnCode,     -- Output
                            _callingUser => _callingUser);

    End If;

    If _returnCode = '' Then
        -----------------------------------------------------------
        -- Update the factors
        -----------------------------------------------------------
        --

        Call update_requested_run_factors (
                                _factorList,
                                _message => _message,           -- Output
                                _returnCode => _returnCode,     -- Output
                                _callingUser => _callingUser);
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := '';
    Call post_usage_log_entry ('UpdateRequestedRunBlockingAndFactors', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.update_requested_run_blocking_and_factors IS 'UpdateRequestedRunBlockingAndFactors';