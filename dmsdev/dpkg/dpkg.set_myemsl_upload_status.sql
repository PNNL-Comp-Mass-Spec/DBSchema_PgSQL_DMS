--
-- Name: set_myemsl_upload_status(integer, integer, integer, integer, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.set_myemsl_upload_status(IN _entryid integer, IN _datapackageid integer, IN _available integer, IN _verified integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the status for an entry in dpkg.t_myemsl_uploads
**
**      Updates column Available if Step 5 is "completed"
**      Updates column Verified  if Step 6 is "verified"
**
**      For example, see https://ingestdms.my.emsl.pnl.gov/get_state?job_id=2825321
**
**  Arguments:
**    _entryID          Row identifier in dpkg.t_myemsl_uploads
**    _dataPackageID    Used as a safety check to confirm that we're updating a valid entry
**    _available        1 if the data was successfully ingested, otherwise 0
**    _verified         1 if the data was successfully verified, otherwise 0
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   09/25/2013 mem - Initial version
**          05/20/2019 mem - Add Set XACT_ABORT
**          08/16/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _entryID       := Coalesce(_entryID, 0);
    _dataPackageID := Coalesce(_dataPackageID, 0);
    _available     := Coalesce(_available, 0);
    _verified      := Coalesce(_verified, 0);

    If _entryID <= 0 Then
        _message := '_entryID must be positive; unable to continue';
        _returnCode := 'U5201';
        RETURN;
    End If;

    If _dataPackageID <= 0 Then
        _message := '_dataPackageID must be positive; unable to continue';
        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure this is a valid entry
    ---------------------------------------------------

    If Not Exists (SELECT entry_id FROM dpkg.t_myemsl_uploads WHERE entry_id = _entryID AND data_pkg_id = _dataPackageID) Then
        _message := format('Entry %s does not correspond to data package %s', _entryID, _dataPackageID);
        _returnCode := 'U5203';
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
           verified <> _verified);
END
$$;


ALTER PROCEDURE dpkg.set_myemsl_upload_status(IN _entryid integer, IN _datapackageid integer, IN _available integer, IN _verified integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_myemsl_upload_status(IN _entryid integer, IN _datapackageid integer, IN _available integer, IN _verified integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.set_myemsl_upload_status(IN _entryid integer, IN _datapackageid integer, IN _available integer, IN _verified integer, INOUT _message text, INOUT _returncode text) IS 'SetMyEMSLUploadStatus';

