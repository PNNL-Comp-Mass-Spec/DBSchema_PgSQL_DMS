--
-- Name: check_for_myemsl_errors(integer, timestamp without time zone, timestamp without time zone, boolean, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.check_for_myemsl_errors(IN _mostrecentdays integer DEFAULT 2, IN _startdate timestamp without time zone DEFAULT NULL::timestamp without time zone, IN _enddate timestamp without time zone DEFAULT NULL::timestamp without time zone, IN _logerrors boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for anomalies in dpkg.t_myemsl_uploads
**
**  Arguments:
**    _mostRecentDays   Threshold to use when searching for errors
**    _startDate        Start date (only used if _mostRecentDays is 0 or negative)
**    _endDate          End date   (only used if _mostRecentDays is 0 or negative)
**    _logErrors        When true, log an error message if more than 1% of the uploads failed, or more than 5% of the uploads were duplicates (uplading the same data package more than once)
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   12/10/2013 mem - Initial version
**          08/15/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          08/22/2024 mem - Pass _logErrorsToPublicLogTable to post_log_entry() for warning messages
**
*****************************************************/
DECLARE
    _uploadAttempts int;
    _uploadErrors int;
    _uploadErrorRate numeric := 0;
    _dataPkgFolderUploads int;
    _duplicateUploads int;
    _duplicateRate numeric := 0;
    _msg text;
    _blankLineShown boolean := false;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------

    _mostRecentDays := Coalesce(_mostRecentDays, 0);
    _logErrors      := Coalesce(_logErrors, true);

    If _mostRecentDays > 0 Then
        _endDate   := CURRENT_TIMESTAMP;
        _startDate := _endDate + make_interval(days => -Abs(_mostRecentDays));
    Else
        _startDate := Coalesce(_startDate, CURRENT_TIMESTAMP + make_interval(days => -Abs(2)));
        _endDate   := Coalesce(_endDate,   CURRENT_TIMESTAMP);
    End If;

    -----------------------------------------------
    -- Query the upload stats
    -----------------------------------------------

    SELECT COUNT(entry_id)
    INTO _uploadErrors
    FROM dpkg.t_myemsl_uploads
    WHERE entered BETWEEN _startDate AND _endDate AND
          bytes > 0 AND
          error_code <> 0;

    SELECT COUNT(entry_id)
    INTO _uploadAttempts
    FROM dpkg.t_myemsl_uploads
    WHERE entered BETWEEN _startDate AND _endDate;

    SELECT COUNT(*),
           SUM(CASE WHEN UploadAttempts > 1 THEN 1
                    ELSE 0
               END)
    INTO _dataPkgFolderUploads, _duplicateUploads
    FROM (SELECT data_pkg_id,
                 subfolder,
                 COUNT(entry_id) AS UploadAttempts
          FROM dpkg.t_myemsl_uploads
          WHERE entered BETWEEN _startDate AND _endDate
          GROUP BY data_pkg_id, subfolder
         ) UploadsByDataPkgAndFolder;

    If _uploadAttempts > 0 Then
        _uploadErrorRate := _uploadErrors / _uploadAttempts::real;
    End If;

    If _dataPkgFolderUploads > 0 Then
        _duplicateRate := _duplicateUploads / _dataPkgFolderUploads::real;
    End If;

    If _uploadErrorRate > 0.01 Then

        _msg := format('More than 1%% of the uploads to MyEMSL had an error; error rate: %s%% for %s upload attempts',
                            Round(_uploadErrorRate * 100, 0), _uploadAttempts);

        If _logErrors Then
            CALL public.post_log_entry ('Error', _msg, 'Check_For_MyEMSL_Errors', 'dpkg', _logErrorsToPublicLogTable => false);
        Else
            If Not _blankLineShown Then
                RAISE INFO '';
                _blankLineShown := true;
            End If;

            RAISE WARNING '%', _msg;
        End If;

        _message := public.append_to_text(_message, _msg);
    End If;

    If _duplicateRate > 0.05 Then

        _msg := format('More than 5%% of the uploads to MyEMSL involved uploading the same data package and subfolder 2 or more times; '
                       'duplicate rate: %s%% for %s DataPkg/folder combos',
                       Round(_duplicateRate * 100, 0), _dataPkgFolderUploads);

        If _logErrors Then
            CALL public.post_log_entry ('Error', _msg, 'Check_For_MyEMSL_Errors', 'dpkg', _logErrorsToPublicLogTable => false);
        Else
            If Not _blankLineShown Then
                RAISE INFO '';
                _blankLineShown := true;
            End If;

            RAISE WARNING '%', _msg;
        End If;

         _message := public.append_to_text(_message, _msg);
    End If;

END
$$;


ALTER PROCEDURE dpkg.check_for_myemsl_errors(IN _mostrecentdays integer, IN _startdate timestamp without time zone, IN _enddate timestamp without time zone, IN _logerrors boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE check_for_myemsl_errors(IN _mostrecentdays integer, IN _startdate timestamp without time zone, IN _enddate timestamp without time zone, IN _logerrors boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.check_for_myemsl_errors(IN _mostrecentdays integer, IN _startdate timestamp without time zone, IN _enddate timestamp without time zone, IN _logerrors boolean, INOUT _message text, INOUT _returncode text) IS 'CheckForMyEMSLErrors';

