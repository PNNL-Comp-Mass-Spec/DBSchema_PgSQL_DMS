--
CREATE OR REPLACE PROCEDURE public.do_analysis_request_operation
(
    _request text,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Perform analysis request operation defined by 'mode'
**
**  Arguments:
**    _request  Analysis job request ID
**    _mode     'delete'
**
**  Auth:   grk
**  Date:   10/13/2004
**          05/05/2005 grk - removed default mode value
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _result int;
    _requestID int;
BEGIN
    _message := '';
    _returnCode:= '';

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

    _request := Trim(Coalesce(_request, ''));

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Delete analysis job request if it is unused
    ---------------------------------------------------

    If _mode = 'delete' Then

        _requestID := public.try_cast(_request, null::int);

        If _requestID Is Null Then
            RAISE WARNING '_request is not an integer: %', _request;

            _returnCode := 'U5201';
            RETURN;
        End If;

        Call delete_analysis_request (_requestID, _message => _message, _returnCode => _returnCode);

        If _returnCode <> '' Then
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

        RETURN
    End If;

    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    _message := 'Mode "' || _mode ||  '" was unrecognized';
    RAISE WARNING '%', _message;

    _returnCode := 'U5202';

END
$$;

COMMENT ON PROCEDURE public.do_analysis_request_operation IS 'DoAnalysisRequestOperation';
