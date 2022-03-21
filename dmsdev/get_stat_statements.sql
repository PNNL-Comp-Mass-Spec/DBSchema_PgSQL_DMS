--
-- Name: get_stat_statements(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_stat_statements() RETURNS SETOF public.pg_stat_statements
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'public', 'mc'
    AS $$
  select
    s.*
  from
    pg_stat_statements s
    join
    pg_database d
      on d.oid = s.dbid and d.datname = current_database()
$$;


ALTER FUNCTION public.get_stat_statements() OWNER TO d3l243;

--
-- Name: FUNCTION get_stat_statements(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_stat_statements() IS 'created for pgwatch2';

--
-- Name: FUNCTION get_stat_statements(); Type: ACL; Schema: public; Owner: d3l243
--

GRANT ALL ON FUNCTION public.get_stat_statements() TO pgwatch2;

