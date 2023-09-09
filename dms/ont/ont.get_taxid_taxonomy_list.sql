--
-- Name: get_taxid_taxonomy_list(integer, integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.get_taxid_taxonomy_list(_taxonomyid integer, _extendedinfo integer) RETURNS public.citext
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of taxonomy information
**
**  Return value: List of items separated by vertical bars, e.g.
**                Rank:Name:Tax_ID|Rank:Name:Tax_ID|Rank:Name:Tax_ID|
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          03/03/2016 mem - Added _extendedInfo
**          03/30/2022 mem - Ported to PostgreSQL
**          06/16/2022 mem - Move Order by clause into the string_agg function
**          05/22/2023 mem - Capitalize reserved word
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _list citext := '';
BEGIN
    SELECT string_agg(format('%s:%s', T.Rank, T.Name), '|' ORDER BY Entry_ID DESC)
    INTO _list
    FROM ont.get_taxid_taxonomy_table(_taxonomyID) T
    WHERE T.Entry_ID = 1 OR
          T.Rank <> 'no rank' OR
          _extendedInfo > 0;

    RETURN _list;
END
$$;


ALTER FUNCTION ont.get_taxid_taxonomy_list(_taxonomyid integer, _extendedinfo integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_taxid_taxonomy_list(_taxonomyid integer, _extendedinfo integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.get_taxid_taxonomy_list(_taxonomyid integer, _extendedinfo integer) IS 'GetTaxIDTaxonomyList';

