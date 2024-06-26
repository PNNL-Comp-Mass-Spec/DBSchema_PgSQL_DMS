--
-- Name: get_table_bloat_approx(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_table_bloat_approx(OUT approx_free_percent double precision, OUT approx_free_space double precision, OUT dead_tuple_percent double precision, OUT dead_tuple_len double precision) RETURNS record
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'public', 'sw', 'cap', 'dpkg', 'mc', 'ont', 'pc', 'logdms', 'logcap', 'logsw'
    AS $$
    select
      avg(approx_free_percent)::double precision as approx_free_percent,
      sum(approx_free_space)::double precision as approx_free_space,
      avg(dead_tuple_percent)::double precision as dead_tuple_percent,
      sum(dead_tuple_len)::double precision as dead_tuple_len
    from
      pg_class c
      join
      pg_namespace n on n.oid = c.relnamespace
      join lateral pgstattuple_approx(c.oid) on (c.oid not in (select relation from pg_locks where mode = 'AccessExclusiveLock'))  -- skip locked tables
    where
      relkind in ('r', 'm')
      and c.relpages >= 128 -- tables >1mb
      and not n.nspname like any (array[E'pg\\_%', 'information_schema'])
$$;


ALTER FUNCTION public.get_table_bloat_approx(OUT approx_free_percent double precision, OUT approx_free_space double precision, OUT dead_tuple_percent double precision, OUT dead_tuple_len double precision) OWNER TO d3l243;

--
-- Name: FUNCTION get_table_bloat_approx(OUT approx_free_percent double precision, OUT approx_free_space double precision, OUT dead_tuple_percent double precision, OUT dead_tuple_len double precision); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_table_bloat_approx(OUT approx_free_percent double precision, OUT approx_free_space double precision, OUT dead_tuple_percent double precision, OUT dead_tuple_len double precision) IS 'created for pgwatch2';

--
-- Name: FUNCTION get_table_bloat_approx(OUT approx_free_percent double precision, OUT approx_free_space double precision, OUT dead_tuple_percent double precision, OUT dead_tuple_len double precision); Type: ACL; Schema: public; Owner: d3l243
--

REVOKE ALL ON FUNCTION public.get_table_bloat_approx(OUT approx_free_percent double precision, OUT approx_free_space double precision, OUT dead_tuple_percent double precision, OUT dead_tuple_len double precision) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_table_bloat_approx(OUT approx_free_percent double precision, OUT approx_free_space double precision, OUT dead_tuple_percent double precision, OUT dead_tuple_len double precision) TO pgwatch2;

