--
CREATE OR REPLACE PROCEDURE pc.add_legacy_file_upload_request
(
    _legacyfileName text,
    _authenticationHash text default '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds or changes the legacy fasta details in T_Legacy_File_Upload_Requests
**
**
**
**  Arguments:
**    _authenticationHash   Sha1 hash for the file
**
**  Auth:   kja
**  Date:   01/11/2006
**          02/11/2009 mem - Added parameter _authenticationHash
**          09/03/2010 mem - Now updating the stored Authentication_Hash value if _authenticationHash differs from the stored value
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _memberID int;
    _legacyFileID int;
    _authenticationHashStored text;
    _requestID int;
    _transName text;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT legacy_file_id, authentication_hash
    INTO _legacyFileID, _authenticationHashStored
    FROM pc.t_legacy_file_upload_requests
    WHERE legacy_filename = _legacyFileName

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    if _myRowCount > 0 Then
        -- Entry already exists; update the hash if different
        if Coalesce(_authenticationHashStored, '') <> Coalesce(_authenticationHash, '') Then
            UPDATE pc.t_legacy_file_upload_requests;
        End If;
            SET Authentication_Hash = _authenticationHash
            WHERE Legacy_File_ID = _legacyFileID

        Return 0
    End If;

    ---------------------------------------------------
    -- Get File ID from DMS
    ---------------------------------------------------

    SELECT ID INTO _legacyFileID
    FROM V_Legacy_Static_File_Locations
    WHERE Filename = _legacyFileName

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    if _myRowCount = 0 Then
        return 0
    End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'AddLegacyFileUploadRequest';
    begin transaction _transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    INSERT INTO pc.t_legacy_file_upload_requests (
        legacy_file_id,
        legacy_filename,
        date_requested,
        authentication_hash)
    VALUES (
        _legacyFileID,
        _legacyFileName,
        CURRENT_TIMESTAMP,
        _authenticationHash)
    RETURNING upload_request_id
    INTO _requestID

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    if _myError <> 0 Then
        rollback transaction _transName
        _msg := 'Insert operation failed: "' || _legacyFileName || '"';
        RAISERROR (_msg, 10, 1)
        return 51007
    End If;

    commit transaction _transName

    return _requestID
END
$$;

COMMENT ON PROCEDURE pc.add_legacy_file_upload_request IS 'AddLegacyFileUploadRequest';
