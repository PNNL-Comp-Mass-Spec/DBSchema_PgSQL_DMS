--
CREATE OR REPLACE PROCEDURE pc.delete_protein_collection_members
(
    _collectionID int,
    INOUT _message text,
    _numProteinsForReLoad int = 0
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Deletes Protein Collection Member Entries from a given Protein Collection ID
**          Called by the Organism Database Handler when replacing the proteins for an existing protein collection
**
**  Arguments:
**    _numProteinsForReLoad   Number of proteins that will be associated with this collection after they are added to the database following this delete
**
**  Auth:   kja
**  Date:   10/07/2004 kja - Initial version
**          07/20/2015 mem - Now setting NumProteins and TotalResidues to 0 in T_Protein_Collections
**          09/14/2015 mem - Added parameter _numProteinsForReLoad
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _result int;
    _collectionState int;
    _collectionName text;
    _stateName text;
    _transName text;
BEGIN
    _numProteinsForReLoad := Coalesce(_numProteinsForReLoad, 0);
    _message := ''    ;

    ---------------------------------------------------
    -- Check if collection is OK to delete
    ---------------------------------------------------

    If Not Exists (SELECT * FROM pc.t_protein_collections WHERE protein_collection_id = _collectionID) Then
        _msg := 'Protein collection ID not found: ' || Cast(_collectionID as text);
        RAISERROR (_msg, 10, 1)
        return 51140
    End If;

    SELECT collection_state_id
    INTO _collectionState
    FROM pc.t_protein_collections
    WHERE protein_collection_id = _collectionID

    SELECT collection_name
    INTO _collectionName
    FROM pc.t_protein_collections
    WHERE (protein_collection_id = _collectionID)

    SELECT state INTO _stateName
    FROM pc.t_protein_collection_states
    WHERE (collection_state_id = _collectionState)

    if _collectionState > 2     Then
        _msg := 'Cannot Delete collection "' || _collectionName || '": ' || _stateName || ' collections are protected';
        RAISERROR (_msg,10, 1)

        return 51140
    End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'DeleteProteinCollectionMembers';
    begin transaction _transName

    ---------------------------------------------------
    -- delete the proteins for this protein collection
    ---------------------------------------------------

    DELETE FROM pc.t_protein_collection_members
    WHERE (protein_collection_id = _collectionID)

    if @@error <> 0 Then
        rollback transaction _transName
        RAISERROR ('Delete from entries table was unsuccessful for collection',
            10, 1)
        return 51130
    End If;

    UPDATE pc.t_protein_collections
    SET num_proteins = _numProteinsForReLoad,
        num_residues = 0
    WHERE protein_collection_id = _collectionID

    commit transaction _transname

    return 0

END
$$;

COMMENT ON PROCEDURE pc.delete_protein_collection_members IS 'DeleteProteinCollectionMembers';
