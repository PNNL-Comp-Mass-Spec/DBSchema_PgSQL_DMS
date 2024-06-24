--
-- Name: do_analysis_request_operation(text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_analysis_request_operation(IN _request text, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Perform analysis job request operation defined by _mode
**
**      The only supported mode is 'delete'
**      The analysis job request can only be deleted if it is not associated with any jobs
**
**  Arguments:
**    _request      Analysis job request ID (as text)
**    _mode         Mode: 'delete'
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   10/13/2004
**          05/05/2005 grk - Removed default mode value
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/03/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _result int;
    _requestID int;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _request := Trim(Coalesce(_request, ''));
    _mode    := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Delete analysis job request if it is unused
    ---------------------------------------------------

    If _mode = 'delete' Then

        _requestID := public.try_cast(_request, null::int);

        If _requestID Is Null Then
            RAISE WARNING 'Request ID is not an integer: %', _request;

            _returnCode := 'U5201';
            RETURN;
        End If;

        CALL public.delete_analysis_request (
                        _requestID  => _requestID,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            RAISE WARNING '%', _message;
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    _message := format('Mode "%s" was unrecognized', _mode);
    RAISE WARNING '%', _message;

    _returnCode := 'U5202';

END
$$;


ALTER PROCEDURE public.do_analysis_request_operation(IN _request text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE do_analysis_request_operation(IN _request text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.do_analysis_request_operation(IN _request text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'DoAnalysisRequestOperation';

