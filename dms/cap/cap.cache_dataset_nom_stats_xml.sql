--
-- Name: cache_dataset_nom_stats_xml(integer, xml, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.cache_dataset_nom_stats_xml(IN _datasetid integer, IN _nomstatsxml xml, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Cache the XML-based NOM stats in table cap.t_dataset_nom_stats_xml
**
**  Arguments:
**    _datasetID            Dataset ID
**    _nomStatsXML          NOM stats XML
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   03/26/2026 mem - Initial version
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

    -----------------------------------------------
    -- Add/Update cap.t_dataset_nom_stats_xml
    -----------------------------------------------

    INSERT INTO cap.t_dataset_nom_stats_xml (dataset_id, nom_stats_xml, cache_date)
    VALUES (_datasetID, _nomStatsXML, CURRENT_TIMESTAMP)
    ON CONFLICT (dataset_id)
    DO UPDATE SET
      nom_stats_xml = EXCLUDED.nom_stats_xml,
      cache_date = CURRENT_TIMESTAMP;

END
$$;


ALTER PROCEDURE cap.cache_dataset_nom_stats_xml(IN _datasetid integer, IN _nomstatsxml xml, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE cache_dataset_nom_stats_xml(IN _datasetid integer, IN _nomstatsxml xml, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.cache_dataset_nom_stats_xml(IN _datasetid integer, IN _nomstatsxml xml, INOUT _message text, INOUT _returncode text) IS 'CacheDatasetNOMStatsXML';

