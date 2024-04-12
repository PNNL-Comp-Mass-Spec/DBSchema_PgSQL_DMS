--
-- Name: check_data_integrity(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.check_data_integrity(IN _logerrors boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for datasets that map to multiple requested runs
**      Intended to be run daily with _logErrors => true
**
**  Arguments:
**    _logErrors    When true, log an error message if one or more datasets is associated with multiple requested runs
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   06/10/2016 mem - Initial Version
**          06/12/2018 mem - Send _maxLength to Append_To_Text
**          06/01/2023 mem - Ported to PostgreSQL
**          06/16/2023 mem - Use named arguments when calling append_to_text()
**          07/11/2023 mem - Use COUNT(request_id) instead of COUNT(*)
**          09/07/2023 mem - Use default delimiter and max length when calling append_to_text()
**
*****************************************************/
DECLARE
    _errMsg text;
    _datasetCount int;
    _firstDatasetID int;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    _logErrors := Coalesce(_logErrors, true);

    ----------------------------------------------------------
    -- Look for datasets that map to multiple requested runs
    ----------------------------------------------------------

    SELECT COUNT(*),
           MIN(FilterQ.dataset_id)
    INTO _datasetCount, _firstDatasetID
    FROM ( SELECT dataset_id
           FROM t_requested_run
           WHERE NOT dataset_id IS NULL
           GROUP BY dataset_id
           HAVING COUNT(request_id) > 1 ) FilterQ;

    If _datasetCount > 0 Then

        If _datasetCount = 1 Then
            _errMsg := format('Dataset %s is associated with multiple entries in t_requested_run', _firstDatasetID);
        Else
            _errMsg := format('%s datasets map to multiple entries in t_requested_run; for example %s', _datasetCount, _firstDatasetID);
        End If;

        If Not _logErrors Then
            RAISE WARNING '%', _errMsg;
        Else
            CALL post_log_entry ('Error', _errMsg, 'Check_Data_Integrity');
            RAISE INFO '%', _errMsg;
        End If;

        _message := public.append_to_text(_message, _errMsg);

    ElsIf Not _logErrors Then
        RAISE INFO 'No errors were found';
    End If;

END
$$;


ALTER PROCEDURE public.check_data_integrity(IN _logerrors boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE check_data_integrity(IN _logerrors boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.check_data_integrity(IN _logerrors boolean, INOUT _message text, INOUT _returncode text) IS 'CheckDataIntegrity';

