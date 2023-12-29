--
-- Name: get_protein_collection_state(integer, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.get_protein_collection_state(IN _collectionid integer, INOUT _statename text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get Collection State Name for given protein collection ID
**
**      _stateName will be 'Unknown' if the _collectionID does not exist
**
**  Arguments:
**    _collectionID     Protein collection ID
**    _statename        Output: protein collection state name (will be 'Unknown' if the protein collection ID is not recognized)
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   kja
**  Date:   08/04/2005
**          09/14/2015 mem - Now returning "Unknown" if the protein collection ID does not exist in T_Protein_Collections
**          08/21/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _stateID int;
BEGIN
    _message := '';
    _returnCode := '';

    SELECT collection_state_id
    INTO _stateID
    FROM pc.t_protein_collections
    WHERE protein_collection_id = Coalesce(_collectionID, 0);

    If Not FOUND Then
        _stateName := 'Unknown';
        RETURN;
    End If;

    SELECT state
    INTO _stateName
    FROM pc.t_protein_collection_states
    WHERE collection_state_id = _stateID;

END
$$;


ALTER PROCEDURE pc.get_protein_collection_state(IN _collectionid integer, INOUT _statename text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_protein_collection_state(IN _collectionid integer, INOUT _statename text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.get_protein_collection_state(IN _collectionid integer, INOUT _statename text, INOUT _message text, INOUT _returncode text) IS 'GetProteinCollectionState';

