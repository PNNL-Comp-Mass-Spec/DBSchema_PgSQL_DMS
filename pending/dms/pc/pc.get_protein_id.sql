--
CREATE OR REPLACE PROCEDURE pc.get_protein_id
(
    _length int,
    _hash text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Gets ProteinID for given length and SHA-1 Hash
**
**
**  Auth:   kja
**  Date:   10/06/2004
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _proteinID int;
BEGIN
    _proteinID := 0;

    SELECT protein_id FROM pc.t_proteins INTO _proteinID
     WHERE (length = _length AND sha1_hash = _hash)

    return _proteinID
END
$$;

COMMENT ON PROCEDURE pc.get_protein_id IS 'GetProteinID';
