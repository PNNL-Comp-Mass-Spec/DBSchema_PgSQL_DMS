--
-- Name: get_unique_protein_ids(integer, integer); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.get_unique_protein_ids(_collection_1 integer, _collection_2 integer) RETURNS TABLE(protein_id integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Show the Protein_IDs present in collection_1 that are not in collection_2
**
**  Auth:   kja
**  Date:   04/16/2004 kja - Initial version
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/02/2023 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN

    RETURN QUERY
    WITH
    Collection_1 (protein_ID, protein_collection_ID) AS
      ( SELECT PCM1.Protein_ID,
               PCM1.Protein_Collection_ID
        FROM pc.T_Protein_Collection_Members PCM1
        WHERE PCM1.Protein_Collection_ID = _collection_1 ),
    Collection_2 ( protein_ID, protein_collection_ID) AS
      ( SELECT PCM2.Protein_ID,
               PCM2.Protein_Collection_ID
        FROM pc.T_Protein_Collection_Members PCM2
        WHERE PCM2.Protein_Collection_ID = _collection_2 )
    SELECT collection_2.protein_ID
    FROM Collection_1
         RIGHT OUTER JOIN Collection_2
           ON Collection_1.Protein_ID = Collection_2.protein_ID
    WHERE Collection_1.Protein_ID IS NULL;

END
$$;


ALTER FUNCTION pc.get_unique_protein_ids(_collection_1 integer, _collection_2 integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_unique_protein_ids(_collection_1 integer, _collection_2 integer); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON FUNCTION pc.get_unique_protein_ids(_collection_1 integer, _collection_2 integer) IS 'GetUniqueProteinIDs';

