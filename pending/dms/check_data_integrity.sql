--
CREATE OR REPLACE PROCEDURE public.check_data_integrity
(
    _logErrors boolean := true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Run miscellaneous data integrity checks
**      Intended to be run daily with _logErrors => true
**
**  Auth:   mem
**  Date:   06/10/2016 mem - Initial Version
**          06/12/2018 mem - Send _maxLength to AppendToText
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _errMsg text;
    _datasetCount int;
    _firstDatasetID int;
BEGIN
    _message := '';
    _returnCode:= '';

    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    _logErrors := Coalesce(_logErrors, true);

    ----------------------------------------------------------
    -- Look for datasets that map to multiple requested runs
    ----------------------------------------------------------

    SELECT COUNT(*)
           MIN(FilterQ.dataset_id)
    INTO _datasetCount, _firstDatasetID
    FROM ( SELECT dataset_id
           FROM t_requested_run
           WHERE NOT dataset_id IS NULL
           GROUP BY dataset_id
           HAVING COUNT(*) > 1 ) FilterQ

    If _datasetCount > 0 Then

        If _datasetCount = 1 Then
            _errMsg := 'Dataset ' || Cast(_firstDatasetID AS text) || ' is associated with multiple entries in t_requested_run';
        Else
            _errMsg := Cast(_datasetCount AS text) || ' datasets map to multiple entries in t_requested_run; for example ' || Cast(_firstDatasetID AS text);
        End If;

        If Not _logErrors Then
            RAISE WARNING '%', _errMsg;
        Else
            CALL post_log_entry ('Error', _errMsg, 'Check_Data_Integrity');
            RAISE INFO '%', _errMsg;
        End If;

        _message := public.append_to_text(_message, _errMsg, 0, '; ', 512);
    End If;

END
$$;

COMMENT ON PROCEDURE public.check_data_integrity IS 'CheckDataIntegrity';
