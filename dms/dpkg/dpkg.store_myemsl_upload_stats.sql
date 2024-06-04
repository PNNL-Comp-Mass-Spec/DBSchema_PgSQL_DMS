--
-- Name: store_myemsl_upload_stats(integer, text, integer, integer, bigint, real, text, integer, text, text, boolean); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.store_myemsl_upload_stats(IN _datapackageid integer, IN _subfolder text, IN _filecountnew integer, IN _filecountupdated integer, IN _bytes bigint, IN _uploadtimeseconds real, IN _statusuri text, IN _errorcode integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Store MyEMSL upload stats in dpkg.t_myemsl_uploads
**
**  Arguments:
**    _dataPackageID        Data package ID
**    _subfolder            Subfolder (empty string if uploaded the dataset directory and all subdirectories)
**    _fileCountNew         Number of new files added
**    _fileCountUpdated     Number of existing files updated
**    _bytes                Bytes transferred
**    _uploadTimeSeconds    Upload time, in seconds
**    _statusURI            Status URI
**    _errorCode            Error code
**    _message              Status message
**    _returnCode           Return code
**    _infoOnly             When true, preview updates
**
**  Auth:   mem
**  Date:   09/25/2013 mem - Initial version
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/15/2017 mem - Add support for status URLs of the form https://ingestdms.my.emsl.pnl.gov/get_state?job_id=1305088
**          05/20/2019 mem - Add Set XACT_ABORT
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/27/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/08/2023 mem - Select a single column when using If Not Exists()
**
*****************************************************/
DECLARE
    _entryID int;
    _charLoc int;
    _substring text;
    _logMsg text := '';
    _invalidFormat boolean;
    _statusURI_PathID int;
    _statusURI_Path text;
    _statusNum int;
    _getStateToken text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _dataPackageID     := Coalesce(_dataPackageID, 0);
    _subfolder         := Trim(Coalesce(_subfolder, ''));
    _fileCountNew      := Coalesce(_fileCountNew, 0);
    _fileCountUpdated  := Coalesce(_fileCountUpdated, 0);
    _bytes             := Coalesce(_bytes, 0);
    _uploadTimeSeconds := Coalesce(_uploadTimeSeconds, 0);
    _statusURI         := Trim(Coalesce(_statusURI, ''));
    _errorCode         := Coalesce(_errorCode, 0);
    _infoOnly          := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Make sure _dataPackageID is defined in dpkg.t_data_package
    ---------------------------------------------------

    If Not Exists (SELECT data_pkg_id FROM dpkg.t_data_package WHERE data_pkg_id = _dataPackageID) Then
        _message := format('Data Package data_pkg_id not found in dpkg.t_data_package: %s', _dataPackageID);
        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        _returnCode := 'U5201';
        RETURN;
    End If;

    -----------------------------------------------
    -- Analyze _statusURI to determine the base URI and the Status Number
    --
    -- For example, in https://ingestdms.my.emsl.pnl.gov/get_state?job_id=1305088
    -- extract out     https://ingestdms.my.emsl.pnl.gov/get_state?job_id=
    -- and also        1305088
    --
    -- Old URL style, in use prior to June 2017:
    --        https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/644749/xml
    -- Base:  https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/
    -- Value: 644749
    -----------------------------------------------

    _statusURI_PathID := 1;
    _statusURI_Path := '';
    _statusNum := null;

    If _statusURI = '' And _fileCountNew = 0 And _fileCountUpdated = 0 Then
        RAISE INFO '_statusURI is empty and file counts are 0; nothing to do';
        _statusURI_PathID := 1;
        RETURN;
    End If;

    -- Setup the log message in case we need it; also, set _invalidFormat to true for now
    _logMsg := format('Unable to extract StatusNum from StatusURI for Data Package %s', _dataPackageID);
    _invalidFormat := true;

    _charLoc := Position('/status/' In Lower(_statusURI));

    If _charLoc = 0 Then

        _getStateToken := 'get_state?job_id=';

        _charLoc := Position(_getStateToken In Lower(_statusURI));

        If _charLoc = 0 Then
            _logMsg := format('%s: did not find either %s or /status/ in %s', _logMsg, _getStateToken, _statusURI);
        Else

            -- Extract out the base path, examples:
            -- https://ingestdms.my.emsl.pnl.gov/get_state?job_id=
            -- https://ingestdmsdev.my.emsl.pnl.gov/get_state?job_id=

            _statusURI_Path := Substring(_statusURI, 1, _charLoc + char_length(_getStateToken) - 1);

            -- Extract out the number
            _substring := Substring(_statusURI, _charLoc + char_length(_getStateToken), 255);

            If char_length(Coalesce(_substring, '')) > 0 Then
                -- _substring should either be an integer, or should start with an integer

                _statusNum := public.extract_integer(_substring);

                If Not _statusNum Is Null Then
                    -- Integer found
                    _invalidFormat := false;
                End If;

            End If;

            If _invalidFormat Then
                _logMsg := format('%s: number not found after %s in %s', _logMsg, _getStateToken, _statusURI);
            End If;

        End If;

    Else
        -- Extract out the base path, for example:
        -- https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/
        _statusURI_Path := Substring(_statusURI, 1, _charLoc + 7);

        -- Extract out the text after /status/, for example:
        -- 644749/xml
        _substring := Substring(_statusURI, _charLoc + 8, 255);

        -- _substring should start with an integer; extract it
        _statusNum := public.extract_integer(_substring);

        If _statusNum Is Null Then
            _logMsg := format('%s: number not found after /status/ in %s', _logMsg, _statusURI);
        Else
           _invalidFormat := false;
        End If;

    End If;

    If _invalidFormat Then
        If Not _infoOnly Then
            If _errorCode = 0 Then
                CALL public.post_log_entry ('Error', _logMsg, 'Store_MyEMSL_Upload_Stats', 'dpkg');
            End If;
        Else
            RAISE INFO '%', _logMsg;
        End If;
    Else
        -- Resolve _statusURI_Path to _statusURI_PathID

        _statusURI_PathID := dpkg.get_uri_path_id(_statusURI_Path, _infoOnly => _infoOnly);

        If _statusURI_PathID <= 1 Then
            _logMsg := format('Unable to resolve StatusURI_Path to URI_PathID for Data Package %s: %s', _dataPackageID, _statusURI_Path);

            If Not _infoOnly Then
                CALL public.post_log_entry ('Error', _logMsg, 'Store_MyEMSL_Upload_Stats', 'dpkg');
            Else
                RAISE INFO '%', _logMsg;
            End If;
        End If;

    End If;

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        _message := format('Preview store upload stats for '
                           'Data_Pkg_ID: %s, Subfolder: %s, '
                           'FileCountNew: %s, FileCountUpdated: %s, MB_Transferred: %s, UploadTimeSeconds: %s, '
                           'URI: %s, StatusURI_PathID: %s, Status_Num: %s, ErrorCode: %s',
                            _dataPackageID, _subfolder,
                            _fileCountNew, _fileCountUpdated,
                            Round(_bytes / 1024.0 / 1024.0, 3),
                            _uploadTimeSeconds,
                            _statusURI, _statusURI_PathID, _statusNum, _errorCode);

        RAISE INFO '%', _message;
        RETURN;
    End If;

    -----------------------------------------------
    -- Add a new row to dpkg.t_myemsl_uploads
    -----------------------------------------------

    INSERT INTO dpkg.t_myemsl_uploads (
        data_pkg_id,
        subfolder,
        file_count_new,
        file_count_updated,
        bytes,
        upload_time_seconds,
        status_uri_path_id,
        status_num,
        error_code,
        entered
    )
    VALUES (_dataPackageID,
            _subfolder,
            _fileCountNew,
            _fileCountUpdated,
            _bytes,
            _uploadTimeSeconds,
            _statusURI_PathID,
            _statusNum,
            _errorCode,
            CURRENT_TIMESTAMP);

END
$$;


ALTER PROCEDURE dpkg.store_myemsl_upload_stats(IN _datapackageid integer, IN _subfolder text, IN _filecountnew integer, IN _filecountupdated integer, IN _bytes bigint, IN _uploadtimeseconds real, IN _statusuri text, IN _errorcode integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE store_myemsl_upload_stats(IN _datapackageid integer, IN _subfolder text, IN _filecountnew integer, IN _filecountupdated integer, IN _bytes bigint, IN _uploadtimeseconds real, IN _statusuri text, IN _errorcode integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.store_myemsl_upload_stats(IN _datapackageid integer, IN _subfolder text, IN _filecountnew integer, IN _filecountupdated integer, IN _bytes bigint, IN _uploadtimeseconds real, IN _statusuri text, IN _errorcode integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'StoreMyEMSLUploadStats';

