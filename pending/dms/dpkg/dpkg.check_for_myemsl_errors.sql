--
CREATE OR REPLACE PROCEDURE dpkg.check_for_myemsl_errors
(
    _mostRecentDays int = 2,
    _startDate datetime = null,
    _endDate datetime = null,
    _logErrors boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Looks for anomalies in T_MyEMSL_Uploads
**
**  Arguments:
**    _startDate   Only used if _mostRecentDays is 0 or negative
**    _endDate     Only used if _mostRecentDays is 0 or negative
**
**  Auth:   mem
**  Date:   12/10/2013 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _uploadAttempts int;
    _uploadErrors int;
    _uploadErrorRate float8 := 0;
    _dataPkgFolderUploads int;
    _duplicateUploads int;
    _duplicateRate float8 := 0;
BEGIN
    _message := '';
    _returnCode:= '';

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    _mostRecentDays := Coalesce(_mostRecentDays, 0);
    _startDate := Coalesce(_startDate, DateAdd(day, -2, CURRENT_TIMESTAMP));

    _endDate := Coalesce(_endDate, CURRENT_TIMESTAMP);
    _logErrors := Coalesce(_logErrors, true);

    If _mostRecentDays > 0 Then
        _endDate := CURRENT_TIMESTAMP;
        _startDate := DateAdd(day, -Abs(_mostRecentDays), _endDate);
    End If;

    -----------------------------------------------
    -- Query the upload stats
    -----------------------------------------------
    --

    SELECT COUNT(*)
    INTO _uploadErrors
    FROM dpkg.t_myemsl_uploads
    WHERE entered BETWEEN _startDate AND _endDate AND
          bytes > 0 AND
          error_code <> 0;

    SELECT COUNT(*)
    INTO _uploadAttempts
    FROM dpkg.t_myemsl_uploads
    WHERE entered BETWEEN _startDate AND _endDate;

    SELECT COUNT(*),
           SUM(CASE WHEN UploadAttempts > 1 THEN 1
                    ELSE 0
               END)
    INTO _dataPkgFolderUploads, _duplicateUploads
    FROM ( SELECT data_pkg_id,
                  subfolder,
                  COUNT(*) AS UploadAttempts
           FROM dpkg.t_myemsl_uploads
           WHERE entered BETWEEN _startDate AND _endDate
           GROUP BY data_pkg_id, subfolder
         ) UploadsByDataPkgAndFolder

    If _uploadAttempts > 0 Then
        _uploadErrorRate := _uploadErrors / _uploadAttempts::float8;
    End If;

    If _dataPkgFolderUploads > 0 Then
        _duplicateRate := _duplicateUploads / _dataPkgFolderUploads::float8;
    End If;

    If _uploadErrorRate > 0.01 Then
        --
        _message := format('More than 1%% of the uploads to MyEMSL had an error; error rate: %s%% for %s upload attempts',
                            Round(_uploadErrorRate * 100, 0), _uploadAttempts);

        If _logErrors Then
            CALL public.post_log_entry ('Error', _message, 'Check_For_MyEMSL_Errors', 'dpkg');
        Else
            RAISE INFO '%', _message;
        End If;

    End If;

    If _duplicateRate > 0.05 Then

        _message := format('More than 5%% of the uploads to MyEMSL involved uploading the same data package and subfolder 2 or more times; duplicate rate: %s%% for %s DataPkg/folder combos',
                            Round(_duplicateRate * 100, 0), _dataPkgFolderUploads);

        If _logErrors Then
            CALL public.post_log_entry ('Error', _message, 'Check_For_MyEMSL_Errors', 'dpkg');
        Else
            RAISE INFO '%', _message;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE dpkg.check_for_myemsl_errors IS 'CheckForMyEMSLErrors';
