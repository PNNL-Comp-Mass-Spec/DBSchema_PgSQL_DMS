--
-- Name: get_load_average(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_load_average(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision) RETURNS record
    LANGUAGE plpythonu SECURITY DEFINER
    AS $$
from os import getloadavg
la = getloadavg()
return [la[0], la[1], la[2]]
$$;


ALTER FUNCTION public.get_load_average(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision) OWNER TO d3l243;

--
-- Name: FUNCTION get_load_average(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_load_average(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision) IS 'created for pgwatch2';

--
-- Name: FUNCTION get_load_average(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_load_average(OUT load_1min double precision, OUT load_5min double precision, OUT load_15min double precision) TO pgwatch2;

