--
CREATE OR REPLACE PROCEDURE pc.add_update_encryption_metadata
(
    _proteinCollectionID int,
    _encryptionPassphrase text,
    _passphraseSHA1Hash text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds encryption metadata for private collections
**
**
**
**  Auth:   kja
**  Date:   04/14/2006
**          12/15/2023 mem - Ported to PostgreSQL
**
**
**      (-50001) = Protein Collection ID not in T_Protein_Collections
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _passPhraseID int;
    _transName text;
BEGIN
    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT protein_collection_id
    FROM pc.t_protein_collections
    WHERE protein_collection_id = _proteinCollectionID

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    if _myError > 0 Then
        _msg := 'Error during Collection ID existence check';
        RAISERROR(_msg, 10, 1)
        return _myError
    End If;

    if _myRowCount = 0 Then
        _msg := 'Error during Collection ID existence check';
        RAISERROR(_msg, 10, 1)
        return -50001
    End If;

    ---------------------------------------------------
    -- Start update transaction
    ---------------------------------------------------

    _transName := 'AddUpdateEncryptionMetadata';
    begin transaction _transName

    ---------------------------------------------------
    -- Update 'Contents_Encrypted' field
    ---------------------------------------------------

    UPDATE pc.t_protein_collections
    SET contents_encrypted = 1
    WHERE protein_collection_id = _proteinCollectionID

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    if _myError <> 0 Then
        rollback transaction _transName
        _msg := 'Encryption state update operation failed: "' || _proteinCollectionID || '"';
        RAISERROR (_msg, 10, 1)
        return -51007
    End If;

    ---------------------------------------------------
    -- Add passphrase to pc.t_encrypted_collection_passphrases
    ---------------------------------------------------

    INSERT INTO pc.t_encrypted_collection_passphrases (
        passphrase,
        protein_collection_id
    ) VALUES (
        _encryptionPassphrase,
        _proteinCollectionID
    )

    SELECT @@Identity INTO _passPhraseID

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    --
    if _myError <> 0 Then
        rollback transaction _transName
        _msg := 'Passphrase insert operation failed: "' || _proteinCollectionID || '"';
        RAISERROR (_msg, 10, 1)
        return -51007
    End If;

    ---------------------------------------------------
    -- Add Passphrase Hash to pc.t_passphrase_hashes
    ---------------------------------------------------

    INSERT INTO pc.t_passphrase_hashes (
        passphrase_sha1_hash,
        protein_collection_id,
        passphrase_id
    ) VALUES (
        _passphraseSHA1Hash,
        _proteinCollectionID,
        _passphraseID
    )

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    --
    if _myError <> 0 Then
        rollback transaction _transName
        _msg := 'Passphrase hash insert operation failed: "' || _proteinCollectionID || '"';
        RAISERROR (_msg, 10, 1)
        return -51007
    End If;

    commit transaction _transName

    RETURN _passPhraseID
END
$$;

COMMENT ON PROCEDURE pc.add_update_encryption_metadata IS 'AddUpdateEncryptionMetadata';
