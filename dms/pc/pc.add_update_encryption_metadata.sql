--
-- Name: add_update_encryption_metadata(integer, text, text, integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_update_encryption_metadata(IN _proteincollectionid integer, IN _encryptionpassphrase text, IN _passphrasesha1hash text, INOUT _passphraseid integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add encryption metadata for private (encrypted) protein collections,
**      adding a new row to two tables: pc.t_encrypted_collection_passphrases and pc.t_passphrase_hashes
**
**      Also sets column contents_encrypted to 1 in pc.t_protein_collections
**
**  Arguments:
**    _proteinCollectionID      Protein collection ID
**    _encryptionPassphrase     Encryption passphrase
**    _passphraseSHA1Hash       Passphrase SHA-1 hash
**    _passphraseID             Output: Passphrase ID of the new row added to pc.t_encrypted_collection_passphrases
**    _message                  Status message
**    _returnCode               Return code
**
**  Returns:
**    _returnCode will have the passphrase ID of the newly added row
**    _returnCode will be '0' if an error
**
**  Auth:   kja
**  Date:   04/14/2006
**          08/21/2023 mem - Ported to PostgreSQL
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

        _returnCode := '0';
        RETURN;
    End If;

    If Exists ( SELECT passphrase_id
                FROM pc.t_encrypted_collection_passphrases
                WHERE passphrase = _encryptionPassphrase AND
                      protein_collection_id = _proteinCollectionID )
    Then
        _message := format('Protein collection ID %s already hass a passphrase in pc.t_encrypted_collection_passphrases', _proteinCollectionID);
        RAISE WARNING '%', _message;

        _returnCode := '0';
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

    INSERT INTO pc.t_encrypted_collection_passphrases( passphrase,
                                                       protein_collection_id )
    VALUES(_encryptionPassphrase, _proteinCollectionID)
    RETURNING passphrase_id
    INTO _passphraseID;

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

    _returnCode := _passphraseID::text;
END
$$;


ALTER PROCEDURE pc.add_update_encryption_metadata(IN _proteincollectionid integer, IN _encryptionpassphrase text, IN _passphrasesha1hash text, INOUT _passphraseid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_encryption_metadata(IN _proteincollectionid integer, IN _encryptionpassphrase text, IN _passphrasesha1hash text, INOUT _passphraseid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_update_encryption_metadata(IN _proteincollectionid integer, IN _encryptionpassphrase text, IN _passphrasesha1hash text, INOUT _passphraseid integer, INOUT _message text, INOUT _returncode text) IS 'AddUpdateEncryptionMetadata';

