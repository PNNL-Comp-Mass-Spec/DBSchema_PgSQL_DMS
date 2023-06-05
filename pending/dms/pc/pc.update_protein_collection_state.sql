--
CREATE OR REPLACE PROCEDURE pc.update_protein_collection_state
(
    _proteinCollectionID int,
    _stateID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a new protein collection member
**
**  Auth:   kja
**  Date:   07/28/2005
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Make sure that the _stateID value exists in
    -- pc.t_protein_collection_states
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

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    UPDATE pc.t_protein_collections
    SET collection_state_id = _stateID,
        date_modified = CURRENT_TIMESTAMP
    WHERE protein_collection_id = _proteinCollectionID;
--
END
$$;

COMMENT ON PROCEDURE pc.update_protein_collection_state IS 'UpdateProteinCollectionState';
