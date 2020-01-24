--
-- Name: square_num(double precision); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.square_num(INOUT value double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
BEGIN
value := value*value;
END
$$;


ALTER FUNCTION public.square_num(INOUT value double precision) OWNER TO d3l243;

