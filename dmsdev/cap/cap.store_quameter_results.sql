--
-- Name: store_quameter_results(integer, xml, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.store_quameter_results(IN _datasetid integer DEFAULT 0, IN _resultsxml xml DEFAULT '<Quameter_Results></Quameter_Results>'::xml, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Store Quameter results by calling public.store_quameter_results
**
**  Arguments:
**    _datasetID    If this value is 0, will determine the dataset name using the contents of _resultsXML
**    _resultsXML   XML holding the Quameter results for a single dataset
**    _message      Status message
**    _returnCode   Return code
**    _infoOnly     When true, preview updates
**
**  Auth:   mem
**  Date:   09/17/2012 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/27/2023 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

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

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    CALL public.store_quameter_results (
                    _datasetID  => _datasetID,
                    _resultsXML => _resultsXML,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode,     -- Output
                    _infoOnly   => _infoOnly);
END
$$;


ALTER PROCEDURE cap.store_quameter_results(IN _datasetid integer, IN _resultsxml xml, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE store_quameter_results(IN _datasetid integer, IN _resultsxml xml, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.store_quameter_results(IN _datasetid integer, IN _resultsxml xml, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'StoreQuameterResults';

