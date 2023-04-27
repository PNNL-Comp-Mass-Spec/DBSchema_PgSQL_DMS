--
CREATE OR REPLACE PROCEDURE pc.add_update_protein_collection_member
(
    _referenceID int,
    _proteinID int,
    _proteinCollectionID int,
    _sortingIndex int,
    _mode text,
    INOUT _message text
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
**  Date:   10/06/2004
**          11/23/2005 kja - Added parameters
**          12/11/2012 mem - Removed transaction
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _memberID int;
BEGIN
    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

--    declare _iDCheck int
--    set _iDCheck = 0
--
--    SELECT _iDCheck = protein_id FROM pc.t_protein_collection_members
--    WHERE protein_collection_id = _proteinCollectionID
--
--    if _iDCheck > 0
--    begin
--        return 1  -- Entry already exists
--    end

    if _mode = 'add' Then
        ---------------------------------------------------
        -- action for add mode
        ---------------------------------------------------
        --
        INSERT INTO pc.t_protein_collection_members (
            original_reference_id,
            protein_id,
            protein_collection_id,
            sorting_index
        ) VALUES (
            _referenceID,
            _proteinID,
            _proteinCollectionID,
            _sortingIndex
        )
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            _msg := 'Insert operation failed for Protein_ID: "' || _proteinID::text || '"';
            RAISERROR (_msg, 10, 1)
            return 51007
        End If;
    End If;

    if _mode = 'update' Then
        ---------------------------------------------------
        -- action for update mode
        ---------------------------------------------------
        --
        UPDATE pc.t_protein_collection_members
        SET sorting_index = _sortingIndex
        WHERE (protein_id = _proteinID and original_reference_id = _referenceID and protein_collection_id = _proteinCollectionID)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
            --
        if _myError <> 0 Then
            _msg := 'Update operation failed for Protein_ID: "' || _proteinID::text || '"';
            RAISERROR (_msg, 10, 1)
            return 51008
        End If;
    End If;

    return _memberID
END
$$;

COMMENT ON PROCEDURE pc.add_update_protein_collection_member IS 'AddUpdateProteinCollectionMember_New';
