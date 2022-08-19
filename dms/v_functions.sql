--
-- Name: v_functions; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_functions AS
 SELECT n.nspname AS schema,
    (p.proname)::public.citext AS name,
        CASE
            WHEN (p.prokind = 'f'::"char") THEN 'function'::text
            WHEN (p.prokind = 'p'::"char") THEN 'procedure'::text
            WHEN (p.prokind = 'a'::"char") THEN 'aggregate function'::text
            WHEN (p.prokind = 'w'::"char") THEN 'window function'::text
            ELSE (p.prokind)::text
        END AS function_type,
    p.proargnames AS arguments,
    p.oid
   FROM (pg_proc p
     LEFT JOIN pg_namespace n ON ((p.pronamespace = n.oid)))
  WHERE (n.nspname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name]));


ALTER TABLE public.v_functions OWNER TO d3l243;

--
-- Name: VIEW v_functions; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_functions IS 'User defined functions and procedures in the database';

--
-- Name: TABLE v_functions; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_functions TO readaccess;
GRANT SELECT ON TABLE public.v_functions TO writeaccess;

