--
-- Name: gettaxidtaxonomylist(integer, integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.gettaxidtaxonomylist(_taxonomyid integer, _extendedinfo integer) RETURNS public.citext
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Builds a delimited list of taxonomy information
**
**  Return value: List of items separated by vertical bars
**
**      Rank:Name:Tax_ID|Rank:Name:Tax_ID|Rank:Name:Tax_ID|
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          03/03/2016 mem - Added _extendedInfo
**          03/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _list citext := '';
BEGIN
    SELECT string_agg(SourceQ.Rank || ':' || SourceQ.Name, '|')
    INTO _list
    FROM (
        SELECT T.rank, T.Name
        FROM ont.GetTaxIDTaxonomyTable ( _taxonomyID ) T
        WHERE T.Entry_ID = 1 OR
              T.Rank <> 'no rank' OR
              _extendedInfo > 0
        ORDER BY T.Entry_ID DESC)
    SourceQ;
    
    Return _list;
END
$$;


ALTER FUNCTION ont.gettaxidtaxonomylist(_taxonomyid integer, _extendedinfo integer) OWNER TO d3l243;

--
-- Name: FUNCTION gettaxidtaxonomylist(_taxonomyid integer, _extendedinfo integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.gettaxidtaxonomylist(_taxonomyid integer, _extendedinfo integer) IS 'GetTaxIDTaxonomyList';

