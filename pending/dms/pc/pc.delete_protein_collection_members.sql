--
CREATE OR REPLACE PROCEDURE pc.delete_protein_collection_members
(
    _collectionID int,
    _numProteinsForReLoad int default 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes Protein Collection Member Entries from a given Protein Collection ID
**      Called by the Organism Database Handler when replacing the proteins for an existing protein collection
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
    _collectionState int;
    _collectionName text;
    _stateName text;
BEGIN
    _message := '';
    _returnCode := '';

    _numProteinsForReLoad := Coalesce(_numProteinsForReLoad, 0);

    ---------------------------------------------------
    -- Check if collection is OK to delete
    ---------------------------------------------------

    If Not Exists (SELECT * FROM pc.t_protein_collections WHERE protein_collection_id = _collectionID) Then
        _message := format('Protein collection ID not found: %s', _collectionID)
        RAISE WARNING '%', _message;

        _returnCode := 'U5140';
        RETURN;
    End If;

    SELECT collection_state_id
    INTO _collectionState
    FROM pc.t_protein_collections
    WHERE protein_collection_id = _collectionID

    SELECT collection_name
    INTO _collectionName
    FROM pc.t_protein_collections
    WHERE (protein_collection_id = _collectionID)

    SELECT state
    INTO _stateName
    FROM pc.t_protein_collection_states
    WHERE (collection_state_id = _collectionState)

    if _collectionState > 2 Then
        _message := 'Cannot delete collection "%s" since it has state %s', _collectionName, _stateName)
        RAISE WARNING '%', _message;

        _returnCode := 'U5141';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete the proteins for this protein collection
    ---------------------------------------------------

    DELETE FROM pc.t_protein_collection_members
    WHERE protein_collection_id = _collectionID;

    UPDATE pc.t_protein_collections
    SET num_proteins = _numProteinsForReLoad,
        num_residues = 0
    WHERE protein_collection_id = _collectionID;

END
$$;

COMMENT ON PROCEDURE pc.delete_protein_collection_members IS 'DeleteProteinCollectionMembers';
