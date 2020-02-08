--
-- Name: square_and_get_cube(double precision); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.square_and_get_cube(INOUT value double precision, OUT cubed double precision) RETURNS record
    LANGUAGE plpgsql
    AS $$
BEGIN
        cubed := value*value*value;
value := value*value;
END
$$;


ALTER FUNCTION public.square_and_get_cube(INOUT value double precision, OUT cubed double precision) OWNER TO d3l243;

