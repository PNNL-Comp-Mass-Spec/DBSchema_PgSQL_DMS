--
-- Name: v_query_row_counts; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_query_row_counts AS
 SELECT pgn.nspname AS schema_name,
    qrc.query_id,
    qrc.object_name,
    qrc.where_clause,
    qrc.row_count,
    qrc.last_used,
    qrc.last_refresh,
    qrc.usage,
    qrc.refresh_interval_hours,
    qrc.entered
   FROM ((public.t_query_row_counts qrc
     LEFT JOIN pg_class pgc ON (((qrc.object_name)::text = pgc.relname)))
     LEFT JOIN pg_namespace pgn ON ((pgn.oid = pgc.relnamespace)));


ALTER VIEW public.v_query_row_counts OWNER TO d3l243;

--
-- Name: TABLE v_query_row_counts; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_query_row_counts TO readaccess;
GRANT SELECT ON TABLE public.v_query_row_counts TO writeaccess;

