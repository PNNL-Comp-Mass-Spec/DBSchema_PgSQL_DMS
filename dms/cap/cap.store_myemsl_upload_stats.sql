--
-- Name: store_myemsl_upload_stats(integer, integer, text, integer, integer, bigint, real, text, integer, integer, integer, text, integer, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.store_myemsl_upload_stats(IN _job integer, IN _datasetid integer, IN _subfolder text, IN _filecountnew integer, IN _filecountupdated integer, IN _bytes bigint, IN _uploadtimeseconds real, IN _statusuri text, IN _errorcode integer, IN _usedtestinstance integer DEFAULT 0, IN _eusinstrumentid integer DEFAULT NULL::integer, IN _eusproposalid text DEFAULT NULL::text, IN _eusuploaderid integer DEFAULT NULL::integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Store MyEMSL upload stats in cap.t_myemsl_uploads
**
**  Arguments:
**    _job                  Capture task job
**    _datasetID            Dataset ID
**    _subfolder            Subfolder (empty string if uploaded the dataset directory and all subdirectories)
**    _fileCountNew         Number of new files added
**    _fileCountUpdated     Number of existing files updated
**    _bytes                Bytes transferred
**    _uploadTimeSeconds    Upload time, in seconds
**    _statusURI            Status URI
**    _errorCode            Error code
**    _usedTestInstance     Normally 0, but can be 1 if the test instance was used
**    _eusInstrumentID      EUS Instrument ID
**    _eusProposalID        EUS Proposal ID (aka Project ID)
**    _eusUploaderID        The EUS ID of the instrument operator
**
**  Auth:   mem
**  Date:   03/29/2012 mem - Initial version
**          04/02/2012 mem - Now populating StatusURI_PathID, ContentURI_PathID, and Status_Num
**          04/06/2012 mem - No longer posting a log message if _statusURI is blank and _fileCountNew=0 and _fileCountUpdated=0
**          08/19/2013 mem - Removed parameter _updateURIPathIDsForExistingJob
**          09/06/2013 mem - No longer using _contentURI
**          09/11/2013 mem - No longer calling post_log_entry if _statusURI is invalid but _errorCode is non-zero
**          10/01/2015 mem - Added parameter _usedTestInstance
**          01/04/2016 mem - Added parameters _eusUploaderID, _eusInstrumentID, and _eusProposalID
**                         - Removed parameter _contentURI
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/15/2017 mem - Add support for status URLs of the form https://ingestdms.my.emsl.pnl.gov/get_state?job_id=1305088
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/27/2023 mem - Ported to PostgreSQL
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _entryID int;
    _charLoc int;
    _subString text;
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

    _job               := Coalesce(_job, 0);
    _datasetID         := Coalesce(_datasetID, 0);
    _subfolder         := Trim(Coalesce(_subfolder, ''));
    _fileCountNew      := Coalesce(_fileCountNew, 0);
    _fileCountUpdated  := Coalesce(_fileCountUpdated, 0);
    _bytes             := Coalesce(_bytes, 0);
    _uploadTimeSeconds := Coalesce(_uploadTimeSeconds, 0);
    _statusURI         := Trim(Coalesce(_statusURI, ''));
    _errorCode         := Coalesce(_errorCode, 0);
    _usedTestInstance  := Coalesce(_usedTestInstance, 0);
    _eusProposalID     := Trim(Coalesce(_eusProposalID, ''));
    _eusUploaderID     := Coalesce(_eusUploaderID, 0);
    _infoOnly          := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Make sure _job is defined in t_tasks
    ---------------------------------------------------

    If Not Exists (SELECT * FROM cap.t_tasks WHERE Job = _job) Then
        _message := format('Job not found in cap.t_tasks: %s', _job);

        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        _returnCode := 'U5201';
        RETURN;
    End If;

    -----------------------------------------------
    -- Analyze _statusURI to determine the base URI and the Status Number
    --
    -- For example, in https://ingestdms.my.emsl.pnl.gov/get_state?job_id=2825266
    -- extract out     https://ingestdms.my.emsl.pnl.gov/get_state?job_id=
    -- and also        2825266
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
    _logMsg := format('Unable to extract Status_Num from Status_URI for capture task job %s, dataset ID %s', _job, _datasetID);
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

            _statusURI_Path := SUBSTRING(_statusURI, 1, _charLoc + char_length(_getStateToken) - 1);

            -- Extract out the number
            _subString := SUBSTRING(_statusURI, _charLoc + char_length(_getStateToken), 255);

            If char_length(Coalesce(_subString, '')) > 0 Then
                -- _subString should either be an integer, or should start with an integer

                _statusNum := public.extract_integer(_subString);

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
        _statusURI_Path := SUBSTRING(_statusURI, 1, _charLoc + 7);

        -- Extract out the text after /status/, for example:
        -- 644749/xml
        _subString := SUBSTRING(_statusURI, _charLoc + 8, 255);

        -- _subString should start with an integer; extract it
        _statusNum := public.extract_integer(_subString);

        If _statusNum Is Null Then
            _logMsg := format('%s: number not found after /status/ in %s', _logMsg, _statusURI);
        Else
           _invalidFormat := false;
        End If;

    End If;

    If _invalidFormat Then
        If Not _infoOnly Then
            If _errorCode = 0 Then
                CALL public.post_log_entry ('Error', _logMsg, 'Store_MyEMSL_Upload_Stats', 'cap');
            End If;
        Else
            RAISE INFO '%', _logMsg;
        End If;
    Else
        -- Resolve _statusURI_Path to _statusURI_PathID

        _statusURI_PathID := cap.get_uri_path_id(_statusURI_Path, _infoOnly => _infoOnly);

        If _statusURI_PathID <= 1 Then
            _logMsg := format('Unable to resolve StatusURI_Path to URI_PathID for capture task job %s, dataset ID %s: %s', _job, _datasetID, _statusURI_Path);

            If Not _infoOnly Then
                CALL public.post_log_entry ('Error', _logMsg, 'Store_MyEMSL_Upload_Stats', 'cap');
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
                           'Job: %s, Dataset_ID: %s, Subfolder: %s, '
                           'FileCountNew: %s, FileCountUpdated: %s, MB_Transferred: %s, UploadTimeSeconds: %s, '
                           'URI: %s, StatusURI_PathID: %s, Status_Num: %s, ErrorCode: %s',
                            _job, _datasetID, _subfolder,
                            _fileCountNew, _fileCountUpdated,
                            Round(_bytes / 1024.0 / 1024.0, 3),
                            _uploadTimeSeconds,
                            _statusURI, _statusURI_PathID, _statusNum, _errorCode);

        RAISE INFO '%', _message;
        RETURN;
    End If;

    If _usedTestInstance = 0 Then

        -----------------------------------------------
        -- Add a new row to cap.t_myemsl_uploads
        -----------------------------------------------

        INSERT INTO cap.t_myemsl_uploads( job,
                                          dataset_id,
                                          subfolder,
                                          file_count_new,
                                          file_count_updated,
                                          bytes,
                                          upload_time_seconds,
                                          status_uri_path_id,
                                          status_num,
                                          eus_instrument_id,
                                          eus_proposal_id,
                                          eus_uploader_id,
                                          error_code,
                                          entered )
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

        INSERT INTO cap.t_myemsl_testuploads( Job,
                                              Dataset_ID,
                                              Subfolder,
                                              FileCountNew,
                                              FileCountUpdated,
                                              Bytes,
                                              UploadTimeSeconds,
                                              StatusURI_PathID,
                                              Status_Num,
                                              EUS_InstrumentID,
                                              EUS_ProposalID,
                                              EUS_UploaderID,
                                              ErrorCode,
                                              Entered )
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


ALTER PROCEDURE cap.store_myemsl_upload_stats(IN _job integer, IN _datasetid integer, IN _subfolder text, IN _filecountnew integer, IN _filecountupdated integer, IN _bytes bigint, IN _uploadtimeseconds real, IN _statusuri text, IN _errorcode integer, IN _usedtestinstance integer, IN _eusinstrumentid integer, IN _eusproposalid text, IN _eusuploaderid integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE store_myemsl_upload_stats(IN _job integer, IN _datasetid integer, IN _subfolder text, IN _filecountnew integer, IN _filecountupdated integer, IN _bytes bigint, IN _uploadtimeseconds real, IN _statusuri text, IN _errorcode integer, IN _usedtestinstance integer, IN _eusinstrumentid integer, IN _eusproposalid text, IN _eusuploaderid integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.store_myemsl_upload_stats(IN _job integer, IN _datasetid integer, IN _subfolder text, IN _filecountnew integer, IN _filecountupdated integer, IN _bytes bigint, IN _uploadtimeseconds real, IN _statusuri text, IN _errorcode integer, IN _usedtestinstance integer, IN _eusinstrumentid integer, IN _eusproposalid text, IN _eusuploaderid integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'StoreMyEMSLUploadStats';

