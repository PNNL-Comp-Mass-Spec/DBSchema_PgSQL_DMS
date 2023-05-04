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
**  Desc:
**      Adds or updates the legacy FASTA details in T_Legacy_File_Upload_Requests
**
**  Arguments:
**    _legacyfileName       Legacy FASTA file name
**    _authenticationHash   SHA-1 hash for the file
**
**  Auth:   kja
**  Date:   01/11/2006
**          02/11/2009 mem - Added parameter _authenticationHash
**          09/03/2010 mem - Now updating the stored Authentication_Hash value if _authenticationHash differs from the stored value
**          05/03/2023 mem - Return 0 if no errors (previously returned the ID of the newly added row, but the calling application does not use that value)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _legacyFileID int;
    _authenticationHashStored text;
    _requestID int;
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

    If FOUND Then
        -- Entry already exists; update the hash if different
        If _authenticationHashStored Is Distinct From _authenticationHash Then
            UPDATE pc.t_legacy_file_upload_requests
            SET Authentication_Hash = _authenticationHash
            WHERE Legacy_File_ID = _legacyFileID;
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Get File ID from t_organism_db_file
    ---------------------------------------------------

    SELECT ID
    INTO _legacyFileID
    FROM V_Legacy_Static_File_Locations
    WHERE file_name = _legacyFileName;

    If Not Found Then
        _message := format('Legacy FASTA file "%s" not found in V_Legacy_Static_File_Locations', _legacyFileName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
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
    INTO _requestID;

    _message := format('Added %s to t_legacy_file_upload_requests; assigned Upload Request ID: %', legacy_filename, _requestID);

    RAISE INFO '%', _message;

END
$$;

COMMENT ON PROCEDURE pc.add_legacy_file_upload_request IS 'AddLegacyFileUploadRequest';
