--
CREATE OR REPLACE PROCEDURE pc.get_protein_reference_id
(
    _name text,
    _nameDescHash text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Gets CollectionID for given FileName
**
**
**  Auth:   kja
**  Date:   10/08/2004
**          11/28/2005 kja - Changed for revised database architecture
**          12/11/2012 mem - Removed commented-out code
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _referenceID int;
BEGIN
    _referenceID := 0;

    SELECT reference_id INTO _referenceID
    FROM pc.t_protein_names
    WHERE (reference_fingerprint = _nameDescHash)

    return _referenceID
-- =============================================
-- Author:        Ken Auberry
-- Create date: 2004-04-16
-- Description:    Shows the shared Protein_IDs for two collections
-- =============================================
END
$$;

COMMENT ON PROCEDURE pc.get_protein_reference_id IS 'GetProteinReferenceID';
