--
CREATE OR REPLACE PROCEDURE pc.update_protein_collection_counts
(
    _collectionID int,
    _numProteins int,
    _numResidues int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Updates the protein and residue counts tracked in T_Protein_Collections for the given collection
**
**  Auth:   mem
**  Date:   09/14/2015 mem - Initial release
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    If Not Exists (SELECT * FROM pc.t_protein_collections WHERE protein_collection_id = _collectionID) Then
        _message := 'Protein collection ID not found in pc.t_protein_collections: ' || Cast(_collectionID as text);
        _myError := 15000;
    Else
        UPDATE pc.t_protein_collections
        SET num_proteins = _numProteins,
            num_residues = _numResidues
        WHERE protein_collection_id = _collectionID

        _message := 'Counts updated for Protein collection ID ' || Cast(_collectionID as text);
    End If;

    return _myError
END
$$;

COMMENT ON PROCEDURE pc.update_protein_collection_counts IS 'UpdateProteinCollectionCounts';
