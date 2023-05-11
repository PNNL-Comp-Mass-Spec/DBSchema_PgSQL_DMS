--
CREATE OR REPLACE PROCEDURE cap.store_myemsl_upload_stats
(
    _job int,
    _datasetID int,
    _subfolder text,
    _fileCountNew int,
    _fileCountUpdated int,
    _bytes bigint,
    _uploadTimeSeconds numeric,
    _statusURI text,
    _errorCode int,
    _usedTestInstance int=0,
    _eusInstrumentID int=null,
    _eusProposalID text=null,
    _eusUploaderID int=null,
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
**  Arguments:
**    _eusInstrumentID   EUS Instrument ID
**    _eusProposalID     EUS Proposal ID
**    _eusUploaderID     The EUS ID of the instrument operator
**
**  Auth:   mem
**  Date:   03/29/2012 mem - Initial version
**          04/02/2012 mem - Now populating StatusURI_PathID, ContentURI_PathID, and Status_Num
**          04/06/2012 mem - No longer posting a log message if _statusURI is blank and _fileCountNew=0 and _fileCountUpdated=0
**          08/19/2013 mem - Removed parameter _updateURIPathIDsForExistingJob
**          09/06/2013 mem - No longer using _contentURI
**          09/11/2013 mem - No longer calling PostLogEntry if _statusURI is invalid but _errorCode is non-zero
**          10/01/2015 mem - Added parameter _usedTestInstance
**          01/04/2016 mem - Added parameters _eusUploaderID, _eusInstrumentID, and _eusProposalID
**                         - Removed parameter _contentURI
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/15/2017 mem - Add support for status URLs of the form https://ingestdms.my.emsl.pnl.gov/get_state?job_id=1305088
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _entryID int;
    _dataset text := '';
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

    _job := Coalesce(_job, 0);
    _datasetID := Coalesce(_datasetID, 0);
    _subfolder := Coalesce(_subfolder, '');
    _statusURI := Coalesce(_statusURI, '');
    _usedTestInstance := Coalesce(_usedTestInstance, 0);
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Make sure _job is defined in t_tasks
    ---------------------------------------------------

    If NOT EXISTS (SELECT * FROM cap.t_tasks where Job = _job) Then
        _message := format('Job not found in t_tasks: %s', _job);

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
        -- Nothing to do; leave _statusURI_PathID as 1
        _statusURI_PathID := 1;
    Else
    -- <a1>

        -- Setup the log message in case we need it; also, set _invalidFormat to true for now
        _logMsg := 'Unable to extract Status_Num from Status_URI for capture task job ' || _job::text || ', dataset ' || _datasetID::text;
        _invalidFormat := true;

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
                _subString := SUBSTRING(_statusURI, _charLoc + char_length(_getStateToken), 255);

                If char_length(Coalesce(_subString, '')) > 0 Then
                    -- Find the first non-numeric character in _subString
                    _charLoc := PATINDEX('%[^0-9]%', _subString);

                    If _charLoc <= 0 Then
                        -- Match not found; _subString is simply an integer
                        _statusNum := public.try_cast(_subString, null::int);
                        If Not _statusNum Is Null Then
                            _invalidFormat := false;
                        End If;
                    End If;

                    If _charLoc > 1 Then
                        _statusNum := public.try_cast(SUBSTRING(_subString, 1, _charLoc - 1), null::int);
                        _invalidFormat := false;
                    End If;
                End If;

                If _invalidFormat Then
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
            _subString := SUBSTRING(_statusURI, _charLoc + 8, 255);

            -- Find the first non-numeric character in _subString
            _charLoc := PATINDEX('%[^0-9]%', _subString);

            If _charLoc <= 0 Then
                -- Match not found; _subString is simply an integer
                _statusNum := public.try_cast(_subString, null::int);
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
                _statusNum := public.try_cast(SUBSTRING(_subString, 1, _charLoc-1), null::int);
                _invalidFormat := false;
            End If;

        End If; -- </b2>

        If _invalidFormat Then
            If Not _infoOnly Then
                If _errorCode = 0 Then
                    Call public.post_log_entry('Error', _logMsg, 'Store_MyEMSL_Upload_Stats';, 'cap');
                End If;
            Else
                RAISE INFO '%', _logMsg;
            End If;
        Else
        -- <b3>
            -- Resolve _statusURI_Path to _statusURI_PathID

            _status_uri_path_id := cap.get_uri_path_id (_statusURI_Path, _infoOnly => _infoOnly);

            If _statusURI_PathID <= 1 Then
                _logMsg := format('Unable to resolve StatusURI_Path to URI_PathID for capture task job %s, dataset ID %s: %s', _job, _datasetID, _statusURI_Path);

                If Not _infoOnly Then
                    Call public.post_log_entry('Error', _logMsg, 'Store_MyEMSL_Upload_Stats', 'cap');
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

        _message := format('Preview store upload stats for ' ||
                           'Job: %s, Dataset_ID: %s, Subfolder: %s, ' ||
                           'FileCountNew: %s, FileCountUpdated: %s, MB_Transferred: %s, UploadTimeSeconds: %s, ' ||
                           'URI: %s, StatusURI_PathID: %s, Status_Num: %s, ErrorCode: %s',
                            _job, _datasetID, _subfolder,
                            _fileCountNew, _fileCountUpdated,
                            round(_bytes / 1024.0 / 1024.0, 3),
                            _uploadTimeSeconds,
                            _statusURI, _statusURI_PathID, _statusNum, _errorCode);

        RAISE INFO '%', _message;
        RETURN;
    End If;

    If _usedTestInstance = 0 Then

        -----------------------------------------------
        -- Add a new row to cap.t_myemsl_uploads
        -----------------------------------------------
        --
        INSERT INTO cap.t_myemsl_uploads (job, dataset_id, subfolder,
                                          file_count_new, file_count_updated,
                                          bytes, upload_time_seconds,
                                          status_uri_path_id, status_num,
                                          eus_instrument_id, eus_proposal_id, eus_uploader_id,
                                          error_code, entered )
        VALUES( _job,
                _datasetID,
                _subfolder,
                _fileCountNew,
                _fileCountUpdated,
                _bytes,
                _uploadTimeSeconds,
                _statusURI_PathID,
                _statusNum,
                _eusInstrumentID,
                _eusProposalID,
                _eusUploaderID,
                _errorCode,
                CURRENT_TIMESTAMP);
    Else
        -----------------------------------------------
        -- Add a new row to T_MyEMSL_TestUploads
        -----------------------------------------------
        --
        INSERT INTO T_MyEMSL_TestUploads (  Job, Dataset_ID, Subfolder,
                                            FileCountNew, FileCountUpdated,
                                            Bytes, UploadTimeSeconds,
                                            StatusURI_PathID, Status_Num,
                                            EUS_InstrumentID, EUS_ProposalID, EUS_UploaderID,
                                            ErrorCode, Entered )
        VALUES( _job,
                _datasetID,
                _subfolder,
                _fileCountNew,
                _fileCountUpdated,
                _bytes,
                _uploadTimeSeconds,
                _statusURI_PathID,
                _statusNum,
                _eusInstrumentID,
                _eusProposalID,
                _eusUploaderID,
                _errorCode,
                CURRENT_TIMESTAMP);
    End If;

END
$$;

COMMENT ON PROCEDURE cap.store_myemsl_upload_stats IS 'StoreMyEMSLUploadStats';
