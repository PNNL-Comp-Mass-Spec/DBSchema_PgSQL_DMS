--
-- Name: get_modification_site_list(integer, integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.get_modification_site_list(_unimodid integer, _hidden integer) RETURNS TABLE(unimod_id integer, sites public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of modification sites for given Unimod ID
**
**  Arguments:
**    _unimodID    Unimod ID
**    _hidden      0 to return normal modification sites, 1 to return hidden modification sites, 2 to return both
**
**  Auth:   mem
**  Date:   05/15/2013 mem - Initial version
**          03/29/2022 mem - Ported to PostgreSQL
**                         - Add support for returning all modification sites when _hidden is greater than 1
**          05/30/2023 mem - Use format() for string concatenation
**          06/07/2023 mem - Add Order By to string_agg()
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT _unimodID AS Unimod_ID, string_agg(SourceQ.Site_Description, ', ' ORDER BY SourceQ.Site_Description)::citext AS Sites
    FROM (
        SELECT CASE WHEN S.position IN ('Anywhere', 'Any N-Term', 'Any C-term')
                      THEN S.site
                    WHEN S.site LIKE '_-term'
                      THEN S.position
                    ELSE format('%s @ %s', S.site, S.position)
               END AS Site_Description
        FROM ont.t_unimod_specificity AS S
        WHERE S.unimod_id = _unimodID AND
              (S.hidden = _hidden OR _hidden > 1)
        ORDER BY Site_Description
    ) SourceQ;
END
$$;


ALTER FUNCTION ont.get_modification_site_list(_unimodid integer, _hidden integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_modification_site_list(_unimodid integer, _hidden integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.get_modification_site_list(_unimodid integer, _hidden integer) IS 'GetModificationSiteList';

