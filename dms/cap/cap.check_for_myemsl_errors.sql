--
-- Name: check_for_myemsl_errors(integer, timestamp without time zone, timestamp without time zone, boolean, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.check_for_myemsl_errors(IN _mostrecentdays integer DEFAULT 2, IN _startdate timestamp without time zone DEFAULT NULL::timestamp without time zone, IN _enddate timestamp without time zone DEFAULT NULL::timestamp without time zone, IN _logerrors boolean DEFAULT true, INOUT _message text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Looks for anomalies in cap.t_myemsl_uploads
**
**  Arguments:
**    _mostRecentDays   Used to determine the threshold for filtering on the Entered column in t_myemsl_uploads
**    _startDate        Start date; only used if _mostRecentDays is 0 or negative
**    _endDate          End date; only used if _mostRecentDays is 0 or negative
**
**  Auth:   mem
**  Date:   12/10/2013 mem - Initial version
**          08/13/2017 mem - Increase the error rate threshold from 1% to 3% since we're now auto-retrying uploads
**          10/07/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _uploadAttempts int;
    _uploadErrors int;
    _uploadErrorRate numeric := 0;
    _datasetFolderUploads int;
    _duplicateUploads int;
    _duplicateRate numeric := 0;
BEGIN

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    _mostRecentDays := Coalesce(_mostRecentDays, 0);
    _startDate := Coalesce(_startDate, CURRENT_TIMESTAMP - Interval '2 days');

    _endDate := Coalesce(_endDate, CURRENT_TIMESTAMP);
    _logErrors := Coalesce(_logErrors, true);
    _message := '';

    If _mostRecentDays > 0 Then
        _endDate := CURRENT_TIMESTAMP;
        _startDate := _endDate - make_interval(0,0,0, _mostRecentDays);
    End If;

    -----------------------------------------------
    -- Query the upload stats
    -----------------------------------------------
    --
    SELECT COUNT(*)
    INTO _uploadErrors
    FROM cap.t_myemsl_uploads
    WHERE entered BETWEEN _startDate AND _endDate AND
          bytes > 0 AND
          error_code <> 0;

    SELECT COUNT(*)
    INTO _uploadAttempts
    FROM cap.t_myemsl_uploads
    WHERE entered BETWEEN _startDate AND _endDate;

    SELECT COUNT(*), Sum(CASE WHEN UploadAttempts > 1 THEN 1 ELSE 0 END)
    INTO _datasetFolderUploads,
         _duplicateUploads
    FROM ( SELECT dataset_id,
                  subfolder,
                  COUNT(*) AS UploadAttempts
           FROM cap.t_myemsl_uploads
           WHERE entered BETWEEN _startDate AND _endDate
           GROUP BY dataset_id, subfolder
         ) UploadsByDatasetAndFolder;

    If _uploadAttempts > 0 Then
        _uploadErrorRate := _uploadErrors / _uploadAttempts::numeric;
    End If;

    If _datasetFolderUploads > 0 Then
        _duplicateRate := _duplicateUploads / _datasetFolderUploads::numeric;
    End If;

    If _uploadErrorRate > 0.03 Then

        _message := format('More than 3%% of the uploads to MyEMSL had an error; error rate: %s%% for %s upload attempts',
                            Round(_uploadErrorRate*100, 1), _uploadAttempts);

        If _logErrors Then
            Call public.post_log_entry ('Error', _message, 'check_for_myemsl_errors', 'cap');
        Else
            RAISE INFO '%', _message;
        End If;

    End If;

    If _duplicateRate > 0.05 Then

        _message := format('More than 5%% of the uploads to MyEMSL involved uploading the same dataset and subfolder 2 or more times; ' ||
                           'duplicate rate: %s%% for %s dataset/folder combos',
                           Round(_duplicateRate * 100, 1), _datasetFolderUploads);

        If _logErrors Then
            Call cap.post_log_entry ('Error', _message, 'check_for_myemsl_errors', 'cap');
        Else
            RAISE INFO '%', _message;
        End If;

    End If;

END
$$;


ALTER PROCEDURE cap.check_for_myemsl_errors(IN _mostrecentdays integer, IN _startdate timestamp without time zone, IN _enddate timestamp without time zone, IN _logerrors boolean, INOUT _message text) OWNER TO d3l243;

--
-- Name: PROCEDURE check_for_myemsl_errors(IN _mostrecentdays integer, IN _startdate timestamp without time zone, IN _enddate timestamp without time zone, IN _logerrors boolean, INOUT _message text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.check_for_myemsl_errors(IN _mostrecentdays integer, IN _startdate timestamp without time zone, IN _enddate timestamp without time zone, IN _logerrors boolean, INOUT _message text) IS 'CheckForMyEMSLErrors';
