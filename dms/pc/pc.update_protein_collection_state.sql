--
-- Name: update_protein_collection_state(integer, integer, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.update_protein_collection_state(IN _proteincollectionid integer, IN _stateid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates protein collection state in pc.t_protein_collections
**
**  Arguments:
**    _proteinCollectionID      Protein collection ID
**    _stateID                  State ID
**
**  Auth:   kja
**  Date:   07/28/2005
**          08/22/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Make sure that the _stateID value exists in pc.t_protein_collection_states
    ---------------------------------------------------

    If Not Exists (
        SELECT collection_state_id
        FROM pc.t_protein_collection_states
        WHERE collection_state_id = _stateID)
    Then
        _message := format('Collection_State_ID %s does not exist', _stateID);
        RAISE WARNING '%', _message;

        _returnCode = 'U5201';
        RETURN;
    End If;

    UPDATE pc.t_protein_collections
    SET collection_state_id = _stateID,
        date_modified = CURRENT_TIMESTAMP
    WHERE protein_collection_id = _proteinCollectionID;

END
$$;


ALTER PROCEDURE pc.update_protein_collection_state(IN _proteincollectionid integer, IN _stateid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_protein_collection_state(IN _proteincollectionid integer, IN _stateid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.update_protein_collection_state(IN _proteincollectionid integer, IN _stateid integer, INOUT _message text, INOUT _returncode text) IS 'UpdateProteinCollectionState';

