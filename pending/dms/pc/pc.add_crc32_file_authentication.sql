--
CREATE OR REPLACE PROCEDURE pc.add_crc32_file_authentication
(
    _collectionID int,
    _cRC32FileHash varchar(8),
    INOUT _message text,
    _numProteins int = 0,
    _totalResidueCount int = 0
    -- If _numProteins is 0 or _totalResidueCount is 0 then T_Protein_Collections will not be updated
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds a CRC32 fingerprint to a given Protein Collection Entry
**
**
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
    _myRowCount int := 0;
    _msg text;
    _transName text;
BEGIN
    _message := '';
    _numProteins := Coalesce(_numProteins, 0);
    _totalResidueCount := Coalesce(_totalResidueCount, 0);

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'AddCRC32FileAuthentication';
    begin transaction _transName

    UPDATE pc.t_protein_collections
    SET
        authentication_hash = _cRC32FileHash,
        date_modified = CURRENT_TIMESTAMP
    WHERE (protein_collection_id = _collectionID)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    if _myError <> 0 Then
        rollback transaction _transName
        _msg := 'Update operation failed!';
        RAISERROR (_msg, 10, 1)
        return 51007
    End If;

    If _numProteins > 0 And _totalResidueCount > 0 Then
        UPDATE pc.t_protein_collections
        SET num_proteins = _numProteins,
            num_residues = _totalResidueCount
        WHERE protein_collection_id = _collectionID
    End If;

    commit transaction _transName

    return 0
END
$$;

COMMENT ON PROCEDURE pc.add_crc32_file_authentication IS 'AddCRC32FileAuthentication';
