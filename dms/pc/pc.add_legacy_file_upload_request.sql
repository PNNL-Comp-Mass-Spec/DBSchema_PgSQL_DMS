--
-- Name: add_legacy_file_upload_request(text, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_legacy_file_upload_request(IN _legacyfilename text, IN _authenticationhash text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds or updates the legacy FASTA details in pc.t_legacy_file_upload_requests
**
**      New rows are added to pc.t_legacy_file_upload_requests when the Analysis Manager
**      uses the OrganismDatabaseHandler DLL to obtain standalone (legacy) FASTA files.
**      The FastaFileMaker.exe program also uses the OrganismDatabaseHandler DLL to obtain FASTA files.
**
**      Table pc.t_legacy_file_upload_requests has one row for each stanalone FASTA file
**
**      When the table was created, the plan was to upload the standalone FASTA files to the database.
**      In reality, standalone FASTA files are not uploaded to the database, so the table name is a bit misleading.
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
**          08/18/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _legacyFileID int;
    _authenticationHashStored text;
    _requestID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _legacyfileName     := Trim(Coalesce(_legacyfileName, ''));
    _authenticationHash := Trim(Coalesce(_authenticationHash, ''));

    If _legacyfileName = '' Then
        _message := 'Legacy FASTA file name cannot be null or empty';
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT legacy_file_id, authentication_hash
    INTO _legacyFileID, _authenticationHashStored
    FROM pc.t_legacy_file_upload_requests
    WHERE legacy_file_name = _legacyFileName::citext;

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
    -- Get File ID from public.t_organism_db_file
    --
    -- Note that legacy (standalone) FASTA files are added to t_organism_db_file either manually,
    -- or via procedure add_update_organism_db_file()
    ---------------------------------------------------

    SELECT ID
    INTO _legacyFileID
    FROM pc.v_legacy_static_file_locations
    WHERE file_name = _legacyFileName;

    If Not Found Then
        _message := format('Legacy FASTA file "%s" not found in pc.v_legacy_static_file_locations', _legacyFileName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    INSERT INTO pc.t_legacy_file_upload_requests( legacy_file_id,
                                                  legacy_file_name,
                                                  date_requested,
                                                  authentication_hash )
    VALUES(_legacyFileID, _legacyFileName, CURRENT_TIMESTAMP, _authenticationHash)
    RETURNING upload_request_id
    INTO _requestID;

    _message := format('Added %s to t_legacy_file_upload_requests; assigned Upload Request ID: %', _legacyFileName, _requestID);

    RAISE INFO '%', _message;

END
$$;


ALTER PROCEDURE pc.add_legacy_file_upload_request(IN _legacyfilename text, IN _authenticationhash text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_legacy_file_upload_request(IN _legacyfilename text, IN _authenticationhash text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_legacy_file_upload_request(IN _legacyfilename text, IN _authenticationhash text, INOUT _message text, INOUT _returncode text) IS 'AddLegacyFileUploadRequest';

