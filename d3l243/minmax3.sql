--
-- Name: minmax3(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.minmax3(a integer, b integer, c integer, OUT min integer, OUT max integer) RETURNS record
    LANGUAGE plpgsql
    AS $$
BEGIN
    min := least(a, b, c);
    max := greatest(a, b, c);
END
$$;


ALTER FUNCTION public.minmax3(a integer, b integer, c integer, OUT min integer, OUT max integer) OWNER TO d3l243;

