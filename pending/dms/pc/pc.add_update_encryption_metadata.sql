--
CREATE OR REPLACE PROCEDURE pc.add_update_encryption_metadata
(
    _proteinCollectionID int,
    _encryptionPassphrase text,
    _passphraseSHA1Hash text,
    OUT _passphraseID int default 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds encryption metadata for private collections
**
**  Auth:   kja
**  Date:   04/14/2006
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    If Not Exists ( SELECT protein_collection_id
                    FROM pc.t_protein_collections
                    WHERE protein_collection_id = _proteinCollectionID )
    Then

        _message := format('Protein collection ID not found: %s', _proteinCollectionID);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update 'Contents_Encrypted' field
    ---------------------------------------------------

    UPDATE pc.t_protein_collections
    SET contents_encrypted = 1
    WHERE protein_collection_id = _proteinCollectionID;

    ---------------------------------------------------
    -- Add passphrase to pc.t_encrypted_collection_passphrases
    ---------------------------------------------------

    INSERT INTO pc.t_encrypted_collection_passphrases (
        passphrase,
        protein_collection_id
    ) VALUES (
        _encryptionPassphrase,
        _proteinCollectionID
    ) RETURNING passphrase_id
    INTO _passPhraseID;

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
    );

    RETURN _passPhraseID
END
$$;

COMMENT ON PROCEDURE pc.add_update_encryption_metadata IS 'AddUpdateEncryptionMetadata';
