--
-- Name: get_unique_protein_ids(integer, integer); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.get_unique_protein_ids(_collection1 integer, _collection2 integer) RETURNS TABLE(protein_id integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Show the protein IDs present in collection 1 that are not in collection 2
**
**  Arguments:
**    _collection1  ID of the first protein collection
**    _collection2  ID of the second protein collection
**
**  Example Usage:
**      -- 68 proteins are in collection 1 but not in collection 2
**      SELECT COUNT(*)
**      FROM pc.get_unique_protein_ids(3872, 3909);
**
**  Auth:   kja
**  Date:   04/16/2004 kja - Initial version
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/02/2023 mem - Ported to PostgreSQL
**          06/21/2024 mem - Remove extra underscore from function arguments
**                         - Use DISTINCT to assure that each protein ID only appears once
**                         - Fix bug that showed number of proteins in collection 2, but not in collection 1
**
*****************************************************/
BEGIN

    RETURN QUERY
    WITH
    Collection1 (protein_id, protein_collection_id) AS
      (SELECT PCM1.protein_id,
              PCM1.protein_collection_id
       FROM pc.t_protein_collection_members PCM1
       WHERE PCM1.protein_collection_id = _collection1),
    Collection2 (protein_id, protein_collection_id) AS
      (SELECT PCM2.protein_id,
              PCM2.protein_collection_id
       FROM pc.T_Protein_Collection_Members PCM2
       WHERE PCM2.protein_collection_id = _collection2)
    SELECT DISTINCT Collection1.protein_id
    FROM Collection1
         LEFT OUTER JOIN Collection2
           ON Collection1.protein_id = Collection2.protein_id
    WHERE Collection2.protein_id IS NULL;

END
$$;


ALTER FUNCTION pc.get_unique_protein_ids(_collection1 integer, _collection2 integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_unique_protein_ids(_collection1 integer, _collection2 integer); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON FUNCTION pc.get_unique_protein_ids(_collection1 integer, _collection2 integer) IS 'GetUniqueProteinIDs';

