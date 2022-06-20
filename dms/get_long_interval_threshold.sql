--
-- Name: get_long_interval_threshold(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_long_interval_threshold() RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns threshold value (in minutes) for interval
**      to be considered a long interval
**
**  Auth:   grk
**  Date:   06/08/2012 grk - initial release
**          06/18/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    RETURN 180;
END
$$;


ALTER FUNCTION public.get_long_interval_threshold() OWNER TO d3l243;

--
-- Name: FUNCTION get_long_interval_threshold(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_long_interval_threshold() IS 'GetLongIntervalThreshold';

