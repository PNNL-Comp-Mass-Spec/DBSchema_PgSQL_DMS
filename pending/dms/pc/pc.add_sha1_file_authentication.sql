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

BEGIN

    UPDATE pc.t_protein_collections
    SET authentication_hash = _crc32FileHash,
        date_modified = CURRENT_TIMESTAMP
    WHERE Protein_Collection_ID = _collectionID;

END
$$;

COMMENT ON PROCEDURE pc.add_sha1_file_authentication IS 'AddSHA1FileAuthentication';
