--
-- Name: v_system_table_activity; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_system_table_activity AS
 SELECT t.schemaname AS schema,
    t.relname AS table_name,
    t.seq_scan AS sequential_scans,
    t.seq_tup_read AS seq_scan_rows_read,
    t.idx_scan AS index_scans,
    t.idx_tup_fetch AS index_scan_rows_read,
    t.n_tup_ins AS rows_inserted,
    t.n_tup_upd AS rows_updated,
    t.n_tup_del AS rows_deleted,
    t.n_ins_since_vacuum AS rows_inserted_since_last_vacuum,
        CASE
            WHEN ((NOT (t.last_autovacuum IS NULL)) AND (t.last_vacuum < t.last_autovacuum)) THEN t.last_autovacuum
            ELSE t.last_vacuum
        END AS last_vacuum,
        CASE
            WHEN ((NOT (t.last_autoanalyze IS NULL)) AND (t.last_analyze < t.last_autoanalyze)) THEN t.last_autoanalyze
            ELSE t.last_analyze
        END AS last_analyze,
    t.vacuum_count,
    t.autovacuum_count,
    t.analyze_count,
    t.autoanalyze_count
   FROM pg_stat_user_tables t;


ALTER TABLE public.v_system_table_activity OWNER TO d3l243;

--
-- Name: VIEW v_system_table_activity; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_system_table_activity IS 'Table access stats; vacuum time is the most recent manual or auto vacuum; analyze time is the most recent manual or auto analyze';

--
-- Name: TABLE v_system_table_activity; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_system_table_activity TO readaccess;

