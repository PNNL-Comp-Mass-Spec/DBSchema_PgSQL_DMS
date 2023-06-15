--
CREATE OR REPLACE PROCEDURE pc.add_update_protein_collection_member
(
    _referenceID int,
    _proteinID int,
    _proteinCollectionID int,
    _sortingIndex int,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds or updates a protein collection member
**
**  Arguments:
**    _referenceID          Protein reference ID
**    _proteinID            Protein ID
**    _proteinCollectionID  Protein collection ID
**    _sortingIndex         Sorting index
**    _mode                 'add' to add a new collection member, 'update' to udpate the sorting index of an existing collection member
**
**  Returns:
**    If _mode is 'add',    _returnCode will be the member_id of the row added to t_protein_collection_members
**    If _mode is 'update', _returnCode will be an empty string
**
**  Auth:   kja
**  Date:   10/06/2004
**          11/23/2005 kja - Added parameters
**          12/11/2012 mem - Removed transaction
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _memberID int;
BEGIN
    _message := '';
    _returnCode := '';

    If _mode = 'add' Then
        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

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
        RETURNING member_id
        INTO _memberID;

        _returnCode := _memberID::text;

    End If;

    If _mode = 'update' Then
        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        UPDATE pc.t_protein_collection_members
        SET sorting_index = _sortingIndex
        WHERE protein_id = _proteinID And
              original_reference_id = _referenceID And
              protein_collection_id = _proteinCollectionID;
    End If;

END
$$;

COMMENT ON PROCEDURE pc.add_update_protein_collection_member IS 'AddUpdateProteinCollectionMember_New';
