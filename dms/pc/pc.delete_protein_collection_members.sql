--
-- Name: delete_protein_collection_members(integer, integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.delete_protein_collection_members(IN _collectionid integer, IN _numproteinsforreload integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete protein collection member entries for a given Protein Collection ID
**      Called by the Organism Database Handler when replacing the proteins for an existing protein collection
**
**  Arguments:
**    _collectionID             Protein collection ID
**    _numProteinsForReload     Number of proteins that will be associated with this collection after they are added to the database following this delete
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   kja
**  Date:   10/07/2004 kja - Initial version
**          07/20/2015 mem - Now setting NumProteins and TotalResidues to 0 in T_Protein_Collections
**          09/14/2015 mem - Added parameter _numProteinsForReload
**          08/21/2023 mem - Ported to PostgreSQL
**          07/26/2024 mem - Allow protein collections with state Offline or Proteins_Deleted to have their protein collection member entries deleted (since they already should be deleted)
**
*****************************************************/
DECLARE
    _collectionState int;
    _collectionName text;
    _stateName text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _collectionID         := Coalesce(_collectionID, 0);
    _numProteinsForReload := Coalesce(_numProteinsForReload, 0);

    ---------------------------------------------------
    -- Check if collection is OK to delete
    ---------------------------------------------------

    If Not Exists (SELECT protein_collection_id FROM pc.t_protein_collections WHERE protein_collection_id = _collectionID) Then
        _message := format('Protein collection ID not found: %s', _collectionID);
        RAISE WARNING '%', _message;

        _returnCode := 'U5140';
        RETURN;
    End If;

    SELECT collection_state_id, collection_name
    INTO _collectionState, _collectionName
    FROM pc.t_protein_collections
    WHERE protein_collection_id = _collectionID;

    SELECT state
    INTO _stateName
    FROM pc.t_protein_collection_states
    WHERE collection_state_id = _collectionState;

    -- Protein collections with state Unknown, New, Provisional, Offline, or Proteins_Deleted can be updated
    -- Protein collections with state Production or Retired cannot be deleted
    If _collectionState IN (3, 4) Then
        _message := format('Cannot delete protein collection %s since it has state %s', _collectionName, _stateName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5141';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete the proteins for this protein collection
    ---------------------------------------------------

    DELETE FROM pc.t_protein_collection_members
    WHERE protein_collection_id = _collectionID;

    ---------------------------------------------------
    -- Update the protein and residue counts in t_protein_collections
    ---------------------------------------------------

        UPDATE pc.t_protein_collections
        SET num_proteins = _numProteinsForReload,
            num_residues = 0
        WHERE protein_collection_id = _collectionID;

END
$$;


ALTER PROCEDURE pc.delete_protein_collection_members(IN _collectionid integer, IN _numproteinsforreload integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_protein_collection_members(IN _collectionid integer, IN _numproteinsforreload integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.delete_protein_collection_members(IN _collectionid integer, IN _numproteinsforreload integer, INOUT _message text, INOUT _returncode text) IS 'DeleteProteinCollectionMembers';

