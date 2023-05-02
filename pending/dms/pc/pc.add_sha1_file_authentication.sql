--
CREATE OR REPLACE PROCEDURE pc.add_sha1_file_authentication
(
    _collectionID int,
    _crc32FileHash text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds a SHA1 fingerprint to a given Protein Collection Entry
**
**
**
**  Auth:   kja
**  Date:   04/15/2005
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _transName text;
BEGIN
    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'AddCRC32FileAuthentication';
    begin transaction _transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    begin

    UPDATE pc.t_protein_collections
    SET authentication_hash = _crc32FileHash,
        date_modified = CURRENT_TIMESTAMP
    WHERE Protein_Collection_ID = _collectionID;

        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            rollback transaction _transName
            _msg := 'Update operation failed!';
            RAISERROR (_msg, 10, 1)
            return 51007
        End If;
    end

    commit transaction _transName

    return 0
END
$$;

COMMENT ON PROCEDURE pc.add_sha1_file_authentication IS 'AddSHA1FileAuthentication';
