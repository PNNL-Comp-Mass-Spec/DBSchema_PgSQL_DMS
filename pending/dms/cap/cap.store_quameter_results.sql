--
CREATE OR REPLACE PROCEDURE cap.store_quameter_results
(
    _datasetID int = 0,
    _resultsXML xml,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Store Quameter results by calling public.store_quameter_results
**
**  Arguments:
**    _datasetID    If this value is 0,  will determine the dataset name using the contents of _resultsXML
**    _resultsXML   XML holding the Quameter results for a single dataset
**
**  Auth:   mem
**  Date:   09/17/2012 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    Call public.store_quameter_results (_datasetID => _datasetID, _resultsXML => _resultsXML, _message => _message, _infoOnly => _infoOnly);

END
$$;

COMMENT ON PROCEDURE cap.store_quameter_results IS 'StoreQuameterResults';
