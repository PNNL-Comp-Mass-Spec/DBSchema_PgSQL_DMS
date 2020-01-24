--
-- Name: getmax3(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.getmax3(a integer, b integer, c integer, OUT max integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
max := greatest(a, b, c);
END
$$;


ALTER FUNCTION public.getmax3(a integer, b integer, c integer, OUT max integer) OWNER TO d3l243;

