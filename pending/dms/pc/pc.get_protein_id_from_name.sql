--
CREATE OR REPLACE PROCEDURE pc.get_protein_id_from_name
(
    _name text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Gets ProteinID for given Protein Name
**
**
**  Auth:   kja
**  Date:   12/07/2005
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _proteinID int;
BEGIN
    -- Moved to bottom of query: TOP 1
    SELECT protein_id FROM pc.t_protein_names INTO _proteinID
     WHERE "name" = _name
    LIMIT 1;

    return _proteinID
END
$$;

COMMENT ON PROCEDURE pc.get_protein_id_from_name IS 'GetProteinIDFromName';
