--
-- Name: v_system_table_activity; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_system_table_activity AS
 SELECT schemaname AS schema,
    relname AS table_name,
    seq_scan AS sequential_scans,
    seq_tup_read AS seq_scan_rows_read,
    idx_scan AS index_scans,
    idx_tup_fetch AS index_scan_rows_read,
    n_tup_ins AS rows_inserted,
    n_tup_upd AS rows_updated,
    n_tup_del AS rows_deleted,
    n_ins_since_vacuum AS rows_inserted_since_last_vacuum,
        CASE
            WHEN ((NOT (last_autovacuum IS NULL)) AND (last_vacuum < last_autovacuum)) THEN last_autovacuum
            ELSE last_vacuum
        END AS last_vacuum,
        CASE
            WHEN ((NOT (last_autoanalyze IS NULL)) AND (last_analyze < last_autoanalyze)) THEN last_autoanalyze
            ELSE last_analyze
        END AS last_analyze,
    vacuum_count,
    autovacuum_count,
    analyze_count,
    autoanalyze_count
   FROM pg_stat_user_tables t;


ALTER VIEW public.v_system_table_activity OWNER TO d3l243;

--
-- Name: VIEW v_system_table_activity; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_system_table_activity IS 'Table access stats; vacuum time is the most recent manual or auto vacuum; analyze time is the most recent manual or auto analyze';

--
-- Name: TABLE v_system_table_activity; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_system_table_activity TO readaccess;
GRANT SELECT ON TABLE public.v_system_table_activity TO writeaccess;

