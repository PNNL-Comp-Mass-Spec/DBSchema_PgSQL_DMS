--
CREATE OR REPLACE PROCEDURE pc.add_crc32_file_authentication
(
    _collectionID int,
    _crc32FileHash text,
    _numProteins int default 0,
    _totalResidueCount int default 0
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a CRC32 fingerprint to a given Protein Collection Entry
**      Note: If _numProteins is 0 or _totalResidueCount is 0, T_Protein_Collections will not be updated
**
**  Arguments:
**    _numProteins         The number of proteins for this protein collection; used to update T_Protein_Collections
**    _totalResidueCount   The number of residues for this protein collection; used to update T_Protein_Collections
**
**  Auth:   kja
**  Date:   04/15/2005
**          07/20/2015 mem - Added parameters _numProteins and _totalResidueCount
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    _numProteins := Coalesce(_numProteins, 0);
    _totalResidueCount := Coalesce(_totalResidueCount, 0);

    UPDATE pc.t_protein_collections
    SET authentication_hash = _crc32FileHash,
        date_modified = CURRENT_TIMESTAMP
    WHERE protein_collection_id = _collectionID;

    If _numProteins > 0 And _totalResidueCount > 0 Then
        UPDATE pc.t_protein_collections
        SET num_proteins = _numProteins,
            num_residues = _totalResidueCount
        WHERE protein_collection_id = _collectionID;
    End If;

END
$$;

COMMENT ON PROCEDURE pc.add_crc32_file_authentication IS 'AddCRC32FileAuthentication';
