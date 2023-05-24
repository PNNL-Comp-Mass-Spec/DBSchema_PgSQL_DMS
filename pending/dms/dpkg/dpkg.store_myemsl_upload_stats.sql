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
    INOUT _message text default '',
    INOUT _returnCode text default '',
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
    _entryID int;
    _charLoc int;
    _subString text;
    _logMsg text := '';
    _invalidFormat boolean;
    _statusURI_PathID int := 1;
    _statusURI_Path text := '';
    _statusNum int := null;
    _getStateToken text := 'get_state?job_id=';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _dataPackageID := Coalesce(_dataPackageID, 0);
    _subfolder := Coalesce(_subfolder, '');
    _statusURI := Coalesce(_statusURI, '');
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Make sure _dataPackageID is defined in dpkg.t_data_package
    ---------------------------------------------------

    If NOT EXISTS (SELECT * FROM dpkg.t_data_package    WHERE data_pkg_id = _dataPackageID) Then
        _message := format('Data Package data_pkg_id not found in dpkg.t_data_package: %s', _dataPackageID);
        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        _returnCode := 'U5201';
        RETURN;
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

    If _statusURI = '' And _fileCountNew = 0 And _fileCountUpdated = 0 Then
        RAISE INFO '_statusURI is empty and file counts are 0; nothing to do'
        RETURN;
    End If;

    -- Setup the log message in case we need it; also, set _invalidFormat to true for now
    _logMsg := format('Unable to extract StatusNum from StatusURI for Data Package %s', _dataPackageID);
    _invalidFormat := true;

    _charLoc := position('/status/' in _statusURI);

    If _charLoc = 0 Then

        _charLoc := position(_getStateToken in _statusURI);

        If _charLoc = 0 Then
            _logMsg := _logMsg || ': did not find either ' || _getStateToken || ' or /status/ in ' || _statusURI;
        Else

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
                    _statusNum := try_cast(_subString, null::int);
                    If Not _statusNum Is Null Then
                        _invalidFormat := false;
                    End If;
                End If;

                If _charLoc > 1 Then
                    _statusNum := try_cast(SUBSTRING(_subString, 1, _charLoc-1), null::int);
                    If Not _statusNum Is Null Then
                        _invalidFormat := false;
                    End If;
                End If;
            End If;

            If _invalidFormat Then
                _logMsg := _logMsg || ': number not found after ' || _getStateToken || ' in ' || _statusURI;
            End If;

        End If;

    Else
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
            _statusNum := try_cast(_subString, null::int);
            If Coalesce(_subString, '') <> '' And Not _statusNum Is Null Then
                _invalidFormat := false;
            Else
                _logMsg := _logMsg || ': number not found after /status/ in ' || _statusURI;
            End If;
        End If;

        If _charLoc = 1 Then
            _logMsg := _logMsg || ': number not found after /status/ in ' || _statusURI;
        End If;

        If _charLoc > 1 Then
            _statusNum := try_cast(SUBSTRING(_subString, 1, _charLoc-1), null::int);
            If Not _statusNum Is Null Then
                _invalidFormat := false;
            End If;
        End If;

    End If;

    If _invalidFormat Then
        If _infoOnly = false Then
            If _errorCode = 0 Then
                CALL public.post_log_entry ('Error', _logMsg, 'Store_MyEMSL_Upload_Stats', 'dpkg');
            End If;
        Else
            RAISE INFO '%', _logMsg;
        End If;
    Else
        -- Resolve _statusURI_Path to _statusURI_PathID

        _status_uri_path_id := Get_URI_Path_ID (_statusURI_Path, _infoOnly => _infoOnly)

        If _statusURI_PathID <= 1 Then
            _logMsg := format('Unable to resolve StatusURI_Path to URI_PathID for Data Package %s: %s', _dataPackageID, _statusURI_Path);

            If _infoOnly = false Then
                CALL public.post_log_entry ('Error', _logMsg, 'Store_MyEMSL_Upload_Stats', 'dpkg');
            Else
                RAISE INFO '%', _logMsg;
            End If;
        Else
            -- Blank out _statusURI since we have successfully resolved it into _statusURI_PathID and _statusNum
            _statusURI := '';
        End If;

    End If;

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        -- ToDo: Use RAISE INFO to show this

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

        RETURN;
    End If;

    -----------------------------------------------
    -- Add a new row to dpkg.t_myemsl_uploads
    -----------------------------------------------
    --
    INSERT INTO dpkg.t_myemsl_uploads( data_pkg_id,
                                       subfolder,
                                       file_count_new,
                                       file_count_updated,
                                       bytes,
                                       upload_time_seconds,
                                       status_uri_path_id,
                                       status_num,
                                       error_code,
                                       entered )
    SELECT _dataPackageID,
           _subfolder,
           _fileCountNew,
           _fileCountUpdated,
           _bytes,
           _uploadTimeSeconds,
           _statusURI_PathID,
           _statusNum,
           _errorCode,
           CURRENT_TIMESTAMP;

END
$$;

COMMENT ON PROCEDURE dpkg.store_myemsl_upload_stats IS 'StoreMyEMSLUploadStats';
