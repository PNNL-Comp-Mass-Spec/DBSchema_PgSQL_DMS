--
-- Name: v_system_locked_objects; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_system_locked_objects AS
 SELECT psa.pid,
    psa.datname AS database,
    psa.usename AS username,
    psa.application_name,
    psa.state,
    psa.query_start,
    (now() - psa.query_start) AS query_runtime,
    psa.xact_start,
    psa.query,
    lt.tables_with_locks,
    lv.views_with_locks,
    lst.system_tables_with_locks
   FROM (((pg_stat_activity psa
     LEFT JOIN ( SELECT a.pid,
            array_agg(DISTINCT c.relname) AS tables_with_locks
           FROM (((pg_stat_activity a
             JOIN pg_locks l ON ((a.pid = l.pid)))
             JOIN pg_class c ON ((l.relation = c.oid)))
             JOIN pg_namespace ns ON ((c.relnamespace = ns.oid)))
          WHERE ((c.relkind = ANY (ARRAY['r'::"char", 'f'::"char", 'p'::"char"])) AND (ns.nspname <> 'pg_catalog'::name))
          GROUP BY a.pid) lt ON ((psa.pid = lt.pid)))
     LEFT JOIN ( SELECT a.pid,
            array_agg(DISTINCT c.relname) AS system_tables_with_locks
           FROM (((pg_stat_activity a
             JOIN pg_locks l ON ((a.pid = l.pid)))
             JOIN pg_class c ON ((l.relation = c.oid)))
             JOIN pg_namespace ns ON ((c.relnamespace = ns.oid)))
          WHERE ((c.relkind = ANY (ARRAY['r'::"char", 'f'::"char", 'p'::"char"])) AND (ns.nspname = 'pg_catalog'::name))
          GROUP BY a.pid) lst ON ((psa.pid = lst.pid)))
     LEFT JOIN ( SELECT a.pid,
            array_agg(DISTINCT c.relname) AS views_with_locks
           FROM (((pg_stat_activity a
             JOIN pg_locks l ON ((a.pid = l.pid)))
             JOIN pg_class c ON ((l.relation = c.oid)))
             JOIN pg_namespace ns ON ((c.relnamespace = ns.oid)))
          WHERE ((c.relkind = ANY (ARRAY['v'::"char", 'm'::"char"])) AND (ns.nspname <> 'pg_catalog'::name))
          GROUP BY a.pid) lv ON ((psa.pid = lv.pid)))
  WHERE ((psa.backend_type = 'client backend'::text) OR ((psa.backend_type IS NULL) AND (COALESCE(psa.usename, 'postgres'::name) <> 'postgres'::name)))
  GROUP BY psa.pid, psa.datname, psa.usename, psa.application_name, psa.state, psa.query, psa.query_start, psa.xact_start, lt.tables_with_locks, lv.views_with_locks, lst.system_tables_with_locks;


ALTER VIEW public.v_system_locked_objects OWNER TO d3l243;

--
-- Name: VIEW v_system_locked_objects; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_system_locked_objects IS 'Locked tables and views, by query; to exclude the current process, use "where pid != pg_backend_pid()"';

--
-- Name: TABLE v_system_locked_objects; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_system_locked_objects TO readaccess;
GRANT SELECT ON TABLE public.v_system_locked_objects TO writeaccess;

