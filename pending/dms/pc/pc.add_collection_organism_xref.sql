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
**  Desc:
**      Adds an entry to T_Collection_Organism_Xref
**
**  Arguments:
**    _proteinCollectionID      Protein collection ID
**    _organismID               Organism ID
**
**  Returns:
**    If a row already exists matching _proteinCollectionID and _organismID, _returnCode will have the member_id of that row
**    Otherwise, _returnCode will have the member_id of the row added to T_Collection_Organism_Xref
**
**  Auth:   kja
**  Date:   06/01/2006
**          08/15/2006 mem - Updated to return _memberID if the mapping already exists, or 0 or a negative number if it doesn't
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _memberID int;
BEGIN
    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    SELECT id
    INTO _memberID
    FROM pc.t_collection_organism_xref
    WHERE protein_collection_id = _proteinCollectionID AND
          organism_id = _organismID;

    If FOUND Then
        _returnCode := _memberID::text;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    INSERT INTO pc.t_collection_organism_xref (protein_collection_id, organism_id)
    VALUES (_proteinCollectionID, _organismID)
    RETURNING ID
    INTO _memberID

    _returnCode := _memberID::text;
END
$$;

COMMENT ON PROCEDURE pc.add_collection_organism_xref IS 'AddCollectionOrganismXRef';
