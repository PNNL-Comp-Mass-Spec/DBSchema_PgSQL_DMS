--
CREATE OR REPLACE PROCEDURE pc.get_protein_collection_state
(
    _collectionID int,
    _stateName text OUTPUT
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Gets Collection State Name for given CollectionID
          Returns state 0 if the _collectionID does not exist
**
**
**  Auth:   kja
**  Date:   08/04/2005
**          09/14/2015 mem - Now returning "Unknown" if the protein collection ID does not exist in T_Protein_Collections
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _stateID int;
BEGIN
    _stateID := 0;
    _stateName := 'Unknown';

    If Exists (Select * From pc.t_protein_collections WHERE protein_collection_id = _collectionID) Then
        SELECT collection_state_id INTO _stateID
        FROM pc.t_protein_collections
        WHERE (protein_collection_id = _collectionID)
    End If;

    SELECT state INTO _stateName
    FROM pc.t_protein_collection_states
    WHERE (collection_state_id = _stateID)

    return 0
END
$$;

COMMENT ON PROCEDURE pc.get_protein_collection_state IS 'GetProteinCollectionState';
