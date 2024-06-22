--
-- Name: get_shared_protein_ids(integer, integer); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.get_shared_protein_ids(_collection1 integer, _collection2 integer) RETURNS TABLE(protein_id integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Show the shared protein IDs for two protein collections
**
**      If a protein collection has multiple instances of the same protein sequence (but different protein names)
**      the returned table will only list the protein ID once
**
**  Arguments:
**    _collection1  ID of the first protein collection
**    _collection2  ID of the second protein collection
**
**  Example usage:
**       --                      Protein collection stats
**       -- Collection_ID  Collection_Name                     Proteins  Distinct_Sequences
**       -- 3872           H_sapiens_UniProt_SPROT_2023-03-01  20407     20332
**       -- 3909           H_sapiens_UniProt_SPROT_2023-09-01  20411     20337
**
**       SELECT PC.protein_collection_id,
**              PC.collection_name,
**              StatsQ.Proteins,
**              StatsQ.Distinct_Sequences
**       FROM (SELECT PCM.protein_collection_id,
**                    COUNT(*) AS Proteins,
**                    COUNT(DISTINCT PCM.protein_id) AS Distinct_Sequences
**             FROM pc.v_protein_collection_members PCM
**             WHERE PCM.protein_collection_id IN (3872, 3909)
**             GROUP BY PCM.protein_collection_id
**            ) StatsQ
**            INNER JOIN pc.t_protein_collections PC
**              ON StatsQ.protein_collection_id = PC.protein_collection_ID;
**
**       -- 20264 protein IDs in common
**       SELECT COUNT(*)
**       FROM pc.get_shared_protein_ids(3872, 3909);
**
**  Auth:   kja
**  Date:   04/16/2004 kja - Initial version
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/02/2023 mem - Ported to PostgreSQL
**          06/21/2024 mem - Remove extra underscore from function arguments
**                         - Use DISTINCT to assure that each protein ID only appears once
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
       FROM pc.t_protein_collection_members PCM2
       WHERE PCM2.protein_collection_id = _collection2)
    SELECT DISTINCT Collection2.protein_id
    FROM Collection1
         INNER JOIN Collection2
           ON Collection1.protein_id = Collection2.protein_id;

END
$$;


ALTER FUNCTION pc.get_shared_protein_ids(_collection1 integer, _collection2 integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_shared_protein_ids(_collection1 integer, _collection2 integer); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON FUNCTION pc.get_shared_protein_ids(_collection1 integer, _collection2 integer) IS 'GetSharedProteinIDs';

