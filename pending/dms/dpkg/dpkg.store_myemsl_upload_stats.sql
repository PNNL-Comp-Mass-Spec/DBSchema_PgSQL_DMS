--
CREATE OR REPLACE PROCEDURE dpkg.store_myemsl_upload_stats
(
    _dataPackageID int,
    _subfolder text,
    _fileCountNew int,
    _fileCountUpdated int,
    _bytes bigint,
    _uploadTimeSeconds real,
    _statusURI text,
    _errorCode int,
    INOUT _message text='',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Store MyEMSL upload stats in T_MyEMSL_Uploads
**
**  Auth:   mem
**  Date:   09/25/2013 mem - Initial version
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/15/2017 mem - Add support for status URLs of the form https://ingestdms.my.emsl.pnl.gov/get_state?job_id=1305088
**          05/20/2019 mem - Add Set XACT_ABORT
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _entryID int;
    _charLoc int;
    _subString text;
    _logMsg text := '';
    _invalidFormat int;
    _statusURI_PathID int := 1;
    _statusURI_Path text := '';
    _statusNum int := null;
    _getStateToken text := 'get_state?job_id=';
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _dataPackageID := Coalesce(_dataPackageID, 0);
    _subfolder := Coalesce(_subfolder, '');
    _statusURI := Coalesce(_statusURI, '');

    _message := '';
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Make sure _dataPackageID is defined in dpkg.t_data_package
    ---------------------------------------------------

    IF NOT EXISTS (SELECT * FROM dpkg.t_data_package    WHERE data_pkg_id = _dataPackageID) Then
        _message := 'Data Package data_pkg_id not found in dpkg.t_data_package: ' || _dataPackageID::text;
        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;
        return 50000
    End If;

    -----------------------------------------------
    -- Analyze _statusURI to determine the base URI and the Status Number
    -- For example, in https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/644749/xml
    -- extract out     https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/
    -- and also        644749
    --
    -- In June 2017 the format changed to
    -- https://ingestdms.my.emsl.pnl.gov/get_state?job_id=1305088
    -- For that, the base is: https://ingestdms.my.emsl.pnl.gov/get_state?job_id=
    -- and the value is 1305088
    -----------------------------------------------
    --
    _statusURI_PathID := 1;
    _statusURI_Path := '';
    _statusNum := null;

    If _statusURI = '' and _fileCountNew = 0 And _fileCountUpdated = 0 Then
        -- Nothing to do; leave _statusURI_PathID as 1
        _statusURI_PathID := 1;
    Else
    -- <a1>

        -- Setup the log message in case we need it; also, set _invalidFormat to 1 for now
        _logMsg := 'Unable to extract StatusNum from StatusURI for Data Package ' || _dataPackageID::text;
        _invalidFormat := 1;

        _charLoc := position('/status/' in _statusURI);
        If _charLoc = 0 Then
        -- <b1>

            _charLoc := position(_getStateToken in _statusURI);
            If _charLoc = 0 Then
                _logMsg := _logMsg || ': did not find either ' || _getStateToken || ' or /status/ in ' || _statusURI;
            Else
            -- <c>

                -- Extract out the base path, examples:
                -- https://ingestdmsdev.my.emsl.pnl.gov/get_state?job_id=
                -- https://ingestdms.my.emsl.pnl.gov/get_state?job_id=
                _statusURI_Path := SUBSTRING(_statusURI, 1, _charLoc + char_length(_getStateToken) - 1);

                -- Extract out the number
                _subString := SubString(_statusURI, _charLoc + char_length(_getStateToken), 255);

                If char_length(Coalesce(_subString, '')) > 0 Then
                    -- Find the first non-numeric character in _subString
                    _charLoc := PATINDEX('%[^0-9]%', _subString);

                    If _charLoc <= 0 Then
                        -- Match not found; _subString is simply an integer
                        _statusNum := Try_Parse(_subString as int);
                        If Not _statusNum Is Null Then
                            _invalidFormat := 0;
                        End If;
                    End If;

                    If _charLoc > 1 Then
                        _statusNum := CONVERT(int, SUBSTRING(_subString, 1, _charLoc-1));
                        _invalidFormat := 0;
                    End If;
                End If;

                If _invalidFormat > 0 Then
                    _logMsg := _logMsg || ': number not found after ' || _getStateToken || ' in ' || _statusURI;
                End If;

            End If; -- </c>

        Else
        -- <b2>
            -- Extract out the base path, for example:
            -- https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/
            _statusURI_Path := SUBSTRING(_statusURI, 1, _charLoc + 7);

            -- Extract out the text after /status/, for example:
            -- 644749/xml
            _subString := SubString(_statusURI, _charLoc + 8, 255);

            -- Find the first non-numeric character in _subString
            _charLoc := PATINDEX('%[^0-9]%', _subString);

            If _charLoc <= 0 Then
                -- Match not found; _subString is simply an integer
                _statusNum := Try_Parse(_subString as int);
                If Coalesce(_subString, '') <> '' And Not _statusNum Is Null Then
                    _invalidFormat := 0;
                Else
                    _logMsg := _logMsg || ': number not found after /status/ in ' || _statusURI;
                End If;
            End If;

            If _charLoc = 1 Then
                _logMsg := _logMsg || ': number not found after /status/ in ' || _statusURI;
            End If;

            If _charLoc > 1 Then
                _statusNum := CONVERT(int, SUBSTRING(_subString, 1, _charLoc-1));
                _invalidFormat := 0;
            End If;

        End If; -- </b2>

        If _invalidFormat <> 0 Then
            If _infoOnly = false Then
                If _errorCode = 0 Then
                    Call post_log_entry 'Error', _logMsg, 'StoreMyEMSLUploadStats';
                End If;
            Else
                RAISE INFO '%', _logMsg;
            End If;
        Else
        -- <b3>
            -- Resolve _statusURI_Path to _statusURI_PathID

            _status_uri_path_id := Get_URI_Path_ID (_statusURI_Path, _infoOnly => _infoOnly)

            If _statusURI_PathID <= 1 Then
                _logMsg := 'Unable to resolve StatusURI_Path to URI_PathID for Data Package ' || _dataPackageID::text || ': ' || _statusURI_Path;

                If _infoOnly = false Then
                    Call post_log_entry 'Error', _logMsg, 'StoreMyEMSLUploadStats'
                Else
                    RAISE INFO '%', _logMsg;
                End If;
            Else
                -- Blank out _statusURI since we have successfully resolved it into _statusURI_PathID and _statusNum
                _statusURI := '';
            End If;

        End If; -- </b3>
    End If; -- </a1>

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        SELECT _dataPackageID AS DataPackageID,
               _subfolder AS Subfolder,
               _fileCountNew AS FileCountNew,
               _fileCountUpdated AS FileCountUpdated,
               _bytes / 1024.0 / 1024.0 AS MB_Transferred,
               _uploadTimeSeconds AS UploadTimeSeconds,
               _statusURI AS URI,
               _statusURI_PathID AS StatusURI_PathID,
               _statusNum as StatusNum,
               _errorCode AS ErrorCode

    Else
    -- <a3>

        -----------------------------------------------
        -- Add a new row to dpkg.t_myemsl_uploads
        -----------------------------------------------
        --
        INSERT INTO dpkg.t_myemsl_uploads(   data_pkg_id,
                                        subfolder,
                                        file_count_new,
                                        file_count_updated,
                                        bytes,
                                        upload_time_seconds,
                                        status_uri_path_id,
                                        status_num,
                                        error_code,
                                        entered )
        SELECT  _dataPackageID,
                _subfolder,
                _fileCountNew,
                _fileCountUpdated,
                _bytes,
                _uploadTimeSeconds,
                _statusURI_PathID,
                _statusNum,
                _errorCode,
                CURRENT_TIMESTAMP
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            _message := 'Error adding new row to dpkg.t_myemsl_uploads for Data Package ' || _dataPackageID::text;
        End If;

    End If; -- </a3>

    If _myError <> 0 Then
        If _message = '' Then
            _message := 'Error in StoreMyEMSLUploadStats';
        End If;

        _message := _message || '; error code = ' || _myError::text;

        If _infoOnly = false Then
            Call post_log_entry 'Error', _message, 'StoreMyEMSLUploadStats';
        End If;
    End If;

    If char_length(_message) > 0 AND _infoOnly Then
        RAISE INFO '%', _message;
    End If;

    Return _myError

END
$$;

COMMENT ON PROCEDURE dpkg.store_myemsl_upload_stats IS 'StoreMyEMSLUploadStats';
