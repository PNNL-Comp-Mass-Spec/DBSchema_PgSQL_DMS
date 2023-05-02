--
CREATE OR REPLACE PROCEDURE pc.add_collection_organism_xref
(
    _proteinCollectionID int,
    _organismID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Adds an entry to T_Collection_Organism_Xref
**
**  Returns the ID value for the mapping in T_Collection_Organism_Xref
**  Returns 0 or a negative number if unable to update T_Collection_Organism_Xref
**
**  Auth:   kja
**  Date:   06/01/2006
**          08/15/2006 mem - Updated to return _memberID if the mapping already exists, or 0 or a negative number if it doesn't
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _memberID int;
    _transName text;
BEGIN
    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    --execute _authid = GetNamingAuthorityID _name

    SELECT id FROM pc.t_collection_organism_xref INTO _memberID
    WHERE (protein_collection_id = _proteinCollectionID AND
           organism_id = _organismID)

    if _memberID > 0 Then
        return _memberID
    End If;

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'AddNamingAuthority';
    begin transaction _transName

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    INSERT INTO pc.t_collection_organism_xref
               (protein_collection_id, organism_id)
    VALUES     (_proteinCollectionID, _organismID)
    RETURNING ID
    INTO _memberID

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    if _myError <> 0 Then
        rollback transaction _transName
        _msg := 'Insert operation failed for Protein Collection: "' || _proteinCollectionID || '"';
        RAISERROR (_msg, 10, 1)
        return -51007
    End If;

    commit transaction _transName

    return _memberID
END
$$;

COMMENT ON PROCEDURE pc.add_collection_organism_xref IS 'AddCollectionOrganismXRef';
