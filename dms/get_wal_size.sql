--
-- Name: get_wal_size(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.get_wal_size() RETURNS bigint
    LANGUAGE sql SECURITY DEFINER
    AS $$
select (sum((pg_stat_file('pg_wal/' || name)).size))::int8 from pg_ls_waldir()
$$;


ALTER FUNCTION public.get_wal_size() OWNER TO d3l243;

--
-- Name: FUNCTION get_wal_size(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_wal_size() IS 'created for pgwatch2';

--
-- Name: FUNCTION get_wal_size(); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_wal_size() TO pgwatch2;
