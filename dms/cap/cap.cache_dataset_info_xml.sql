--
-- Name: cache_dataset_info_xml(integer, xml, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.cache_dataset_info_xml(IN _datasetid integer, IN _datasetinfoxml xml, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Cache the XML-based dataset info in table cap.t_dataset_info_xml
**
**  Arguments:
**    _datasetID            Dataset ID
**    _datasetInfoXML       Dataset info XML
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   05/03/2010 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/07/2022 mem - Ported to PostgreSQL
**          04/27/2023 mem - Use boolean for data type name
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;
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

    -----------------------------------------------
    -- Add/Update cap.t_dataset_info_xml
    -----------------------------------------------

    INSERT INTO cap.t_dataset_info_xml (dataset_id, ds_info_xml, cache_date)
    VALUES (_datasetID, _datasetInfoXML, CURRENT_TIMESTAMP)
    ON CONFLICT (dataset_id)
    DO UPDATE SET
      ds_info_xml = EXCLUDED.ds_info_xml,
      cache_date = CURRENT_TIMESTAMP;

END
$$;


ALTER PROCEDURE cap.cache_dataset_info_xml(IN _datasetid integer, IN _datasetinfoxml xml, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE cache_dataset_info_xml(IN _datasetid integer, IN _datasetinfoxml xml, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.cache_dataset_info_xml(IN _datasetid integer, IN _datasetinfoxml xml, INOUT _message text, INOUT _returncode text) IS 'CacheDatasetInfoXML';

