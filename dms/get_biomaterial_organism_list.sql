--
-- Name: get_biomaterial_organism_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_biomaterial_organism_list(_biomaterialid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of organism names for the given biomaterial
**
**  Return value: comma separated list
**
**  Arguments:
**    _biomaterialID   aka cell culture ID
**
**  Auth:   mem
**  Date:   12/02/2016 mem - Initial version
**          06/18/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(Org.OG_name, ', ' ORDER BY Org.OG_name)
    INTO _result
    FROM t_biomaterial_organisms BiomaterialOrganisms
             INNER JOIN t_organisms Org
               ON BiomaterialOrganisms.organism_id = Org.organism_id
    WHERE BiomaterialOrganisms.biomaterial_id = _biomaterialID;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_biomaterial_organism_list(_biomaterialid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_biomaterial_organism_list(_biomaterialid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_biomaterial_organism_list(_biomaterialid integer) IS 'GetBiomaterialOrganismList';

