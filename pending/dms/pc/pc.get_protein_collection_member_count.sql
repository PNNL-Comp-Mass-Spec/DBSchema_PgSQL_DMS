--
CREATE OR REPLACE PROCEDURE pc.get_protein_collection_member_count
(
    _collectionID int
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Gets Collection Member count for given Collection_ID
**
**
**  Auth:   kja
**  Date:   10/07/2004
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _collectionMemberCount int;
BEGIN
    _collectionMemberCount := 0;

SELECT COUNT(*) INTO _collectionMemberCount
    FROM pc.t_protein_collection_members
    GROUP BY protein_collection_id
    HAVING (protein_collection_id = _collectionID)

    if @@rowcount = 0 Then
        return 0
    End If;

    return(_collectionMemberCount)
END
$$;

COMMENT ON PROCEDURE pc.get_protein_collection_member_count IS 'GetProteinCollectionMemberCount';
