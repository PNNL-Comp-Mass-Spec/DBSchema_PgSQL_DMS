--
-- Name: get_sequences(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_sequences() RETURNS SETOF pg_sequences
    LANGUAGE sql SECURITY DEFINER
    AS $$
  select * from pg_sequences
$$;


ALTER FUNCTION public.get_sequences() OWNER TO d3l243;

--
-- Name: FUNCTION get_sequences(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_sequences() IS 'created for pgwatch2';

--
-- Name: FUNCTION get_sequences(); Type: ACL; Schema: public; Owner: d3l243
--

REVOKE ALL ON FUNCTION public.get_sequences() FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_sequences() TO pgwatch2;

