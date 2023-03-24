--
-- Name: get_protein_collection_id(text); Type: FUNCTION; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION pc.get_protein_collection_id(_collectionname text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Gets CollectionID for given protein collection name
**
**  Arguments:
**    _collectionName   Protein collection name (not the original .fasta file name)
**
**  Auth:   kja
**  Date:   09/29/2004
**          06/26/2019 mem - Add comments and convert tabs to spaces
**          03/23/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _collectionID int;
BEGIN
    SELECT protein_collection_id
    INTO _collectionID
    FROM pc.t_protein_collections
    WHERE (collection_name = _collectionName::citext);

    If FOUND Then
        Return _collectionID;
    End If;

    Return 0;
END
$$;


ALTER FUNCTION pc.get_protein_collection_id(_collectionname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_protein_collection_id(_collectionname text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON FUNCTION pc.get_protein_collection_id(_collectionname text) IS 'GetProteinCollectionID';

