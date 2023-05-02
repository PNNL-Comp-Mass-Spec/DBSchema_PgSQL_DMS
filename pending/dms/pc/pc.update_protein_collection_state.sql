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
**  Desc:   Adds a new protein collection member
**
**
**
**  Auth:   kja
**  Date:   07/28/2005
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _iDCheck int;
    _transName text;
BEGIN
    ---------------------------------------------------
    -- Make sure that the _stateID value exists in
    -- pc.t_protein_collection_states
    ---------------------------------------------------

    _iDCheck := 0;

    SELECT collection_state_id FROM pc.t_protein_collection_states INTO _iDCheck
    WHERE collection_state_id = _stateID

    if _iDCheck = 0 Then
        _message := 'Collection_State_ID: "' || _stateID || '" does not exist';
        RAISERROR (_message, 10, 1)
        return 1  -- State Does not exist
    End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'UpdateProteinCollectionState';
    begin transaction _transName

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
        UPDATE pc.t_protein_collections
        SET
            collection_state_id = _stateID,
            date_modified = CURRENT_TIMESTAMP
        WHERE
            (protein_collection_id = _proteinCollectionID)
    --

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    if _myError <> 0 Then
        rollback transaction _transName
        _message := 'Update operation failed: The state of "' || _proteinCollectionID || '" could not be updated';
        RAISERROR (_message, 10, 1)
        return 51007
    End If;

    commit transaction _transName

    return 0
END
$$;

COMMENT ON PROCEDURE pc.update_protein_collection_state IS 'UpdateProteinCollectionState';
