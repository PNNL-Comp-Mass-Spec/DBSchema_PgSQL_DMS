--
-- Name: get_organism_id(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_organism_id(_organismname text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get organismID for given organism name
**
**  Arguments:
**    _organismName     Organism name
**
**  Returns:
**      OrganismID if found, otherwise 0
**
**  Auth:   grk
**  Date:   01/26/2001
**          09/25/2012 mem - Expanded _organismName to varchar(128)
**          08/03/2017 mem - Add Set NoCount On
**          12/19/2017 mem - Try matching field OG_Short_Name if no match to OG_name
**          10/24/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _organismID int;
BEGIN
    SELECT organism_id
    INTO _organismID
    FROM t_organisms
    WHERE organism = _organismName::citext;

    If FOUND Then
        RETURN _organismID;
    End If;

    SELECT organism_id
    INTO _organismID
    FROM t_organisms
    WHERE short_name = _organismName::citext;

    If FOUND Then
        RETURN _organismID;
    Else
        RETURN 0;
    End If;
END
$$;


ALTER FUNCTION public.get_organism_id(_organismname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_organism_id(_organismname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_organism_id(_organismname text) IS 'GetOrganismID';

