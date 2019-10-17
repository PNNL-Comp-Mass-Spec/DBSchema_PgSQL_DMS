--
-- Name: get_stat_activity(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.get_stat_activity() RETURNS SETOF pg_stat_activity
    LANGUAGE sql SECURITY DEFINER
    AS $$
  select * from pg_stat_activity where datname = current_database() and pid != pg_backend_pid()
$$;


ALTER FUNCTION public.get_stat_activity() OWNER TO d3l243;

--
-- Name: FUNCTION get_stat_activity(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_stat_activity() IS 'created for pgwatch2';

--
-- Name: FUNCTION get_stat_activity(); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_stat_activity() TO pgwatch2;
