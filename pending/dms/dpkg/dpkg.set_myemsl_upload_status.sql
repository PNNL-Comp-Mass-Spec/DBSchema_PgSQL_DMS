--
CREATE OR REPLACE PROCEDURE dpkg.set_myemsl_upload_status
(
    _entryID int,
    _dataPackageID int,
    _available int,
    _verified int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the status for an entry in T_MyEMSL_Uploads
**
**      Updates column Available if Step 5 is "completed"
**      Updates column Verified  if Step 6 is "verified"
**
**      For example, see https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/2271574/xml
**
**  Arguments:
**    _dataPackageID   Used as a safety check to confirm that we're updating a valid entry
**
**  Auth:   mem
**  Date:   09/25/2013 mem - Initial version
**          05/20/2019 mem - Add Set XACT_ABORT
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _entryID := Coalesce(_entryID, 0);
    _dataPackageID := Coalesce(_dataPackageID, 0);
    _available := Coalesce(_available, 0);
    _verified := Coalesce(_verified, 0);

    If _entryID <= 0 Then
        _message := '_entryID must be positive; unable to continue';
        _myError := 60000;
        Return;
    End If;

    If _dataPackageID <= 0 Then
        _message := '_dataPackageID must be positive; unable to continue';
        _myError := 60001;
        Return;
    End If;

    ---------------------------------------------------
    -- Make sure this is a valid entry
    ---------------------------------------------------

    If Not Exists (SELECT * FROM dpkg.t_myemsl_uploads WHERE entry_id = _entryID AND data_pkg_id = _dataPackageID) Then
        _message := 'Entry ' || _entryID::text || ' does not correspond to data package ' || _dataPackageID::text;
        _myError := 60002;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Perform the update
    ---------------------------------------------------

    UPDATE dpkg.t_myemsl_uploads
    SET available = _available,
        verified = _verified
    WHERE entry_id = _entryID AND
          (available <> _available OR
           verified <> _verified)

    If _myError <> 0 Then
        If _message = '' Then
            _message := 'Error in Set_MyEMSL_Upload_Status';
        End If;

        _message := _message || '; error code = ' || _myError::text;

        Call public.post_log_entry ('Error', _message, 'Set_MyEMSL_Upload_Status', 'dpkg');
    End If;

    Return _myError

END
$$;

COMMENT ON PROCEDURE dpkg.set_myemsl_upload_status IS 'SetMyEMSLUploadStatus';
