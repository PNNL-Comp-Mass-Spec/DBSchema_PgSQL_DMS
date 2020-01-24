--
-- Name: get_stat_replication(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.get_stat_replication() RETURNS SETOF pg_stat_replication
    LANGUAGE sql SECURITY DEFINER
    AS $$
  select * from pg_stat_replication
$$;


ALTER FUNCTION public.get_stat_replication() OWNER TO d3l243;

--
-- Name: FUNCTION get_stat_replication(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_stat_replication() IS 'created for pgwatch2';

--
-- Name: FUNCTION get_stat_replication(); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_stat_replication() TO pgwatch2;

