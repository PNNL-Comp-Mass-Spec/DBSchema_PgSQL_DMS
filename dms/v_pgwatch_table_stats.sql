--
-- Name: v_pgwatch_table_stats; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_pgwatch_table_stats AS
 WITH RECURSIVE q_root_part AS (
         SELECT c.oid,
            c.relkind,
            n.nspname AS root_schema,
            c.relname AS root_relname
           FROM (pg_class c
             JOIN pg_namespace n ON ((n.oid = c.relnamespace)))
          WHERE ((c.relkind = ANY (ARRAY['p'::"char", 'r'::"char"])) AND (c.relpersistence <> 't'::"char") AND (NOT (n.nspname ~~ ANY (ARRAY['pg\_%'::text, 'information_schema'::text, '\_timescaledb%'::text]))) AND (NOT (EXISTS ( SELECT pg_inherits.inhrelid,
                    pg_inherits.inhparent,
                    pg_inherits.inhseqno,
                    pg_inherits.inhdetachpending
                   FROM pg_inherits
                  WHERE (pg_inherits.inhrelid = c.oid)))) AND (EXISTS ( SELECT pg_inherits.inhrelid,
                    pg_inherits.inhparent,
                    pg_inherits.inhseqno,
                    pg_inherits.inhdetachpending
                   FROM pg_inherits
                  WHERE (pg_inherits.inhparent = c.oid))))
        ), q_parts(relid, relkind, level, root) AS (
         SELECT q_root_part.oid,
            q_root_part.relkind,
            1 AS "?column?",
            q_root_part.oid
           FROM q_root_part
        UNION ALL
         SELECT i.inhrelid,
            c.relkind,
            (q.level + 1),
            q.root
           FROM ((pg_inherits i
             JOIN q_parts q ON ((i.inhparent = q.relid)))
             JOIN pg_class c ON ((c.oid = i.inhrelid)))
        ), q_tstats AS (
         SELECT ((EXTRACT(epoch FROM now()) * '1000000000'::numeric))::bigint AS epoch_ns,
            ut.relid,
            quote_ident((ut.schemaname)::text) AS tag_schema,
            quote_ident((ut.relname)::text) AS tag_table_name,
            ((quote_ident((ut.schemaname)::text) || '.'::text) || quote_ident((ut.relname)::text)) AS tag_table_full_name,
            pg_table_size((ut.relid)::regclass) AS table_size_b,
            (abs(GREATEST(ceil(log((((pg_table_size((ut.relid)::regclass) + 1))::double precision / ((10)::double precision ^ (6)::double precision)))), (0)::double precision)))::text AS tag_table_size_cardinality_mb,
            pg_total_relation_size((ut.relid)::regclass) AS total_relation_size_b,
                CASE
                    WHEN (c.reltoastrelid <> (0)::oid) THEN pg_total_relation_size((c.reltoastrelid)::regclass)
                    ELSE (0)::bigint
                END AS toast_size_b,
            (EXTRACT(epoch FROM (now() - GREATEST(ut.last_vacuum, ut.last_autovacuum))))::bigint AS seconds_since_last_vacuum,
            (EXTRACT(epoch FROM (now() - GREATEST(ut.last_analyze, ut.last_autoanalyze))))::bigint AS seconds_since_last_analyze,
                CASE
                    WHEN ('autovacuum_enabled=off'::text = ANY (c.reloptions)) THEN 1
                    ELSE 0
                END AS no_autovacuum,
            ut.seq_scan,
            ut.seq_tup_read,
            COALESCE(ut.idx_scan, (0)::bigint) AS idx_scan,
            COALESCE(ut.idx_tup_fetch, (0)::bigint) AS idx_tup_fetch,
            ut.n_tup_ins,
            ut.n_tup_upd,
            ut.n_tup_del,
            ut.n_tup_hot_upd,
            ut.n_live_tup,
            ut.n_dead_tup,
            ut.vacuum_count,
            ut.autovacuum_count,
            ut.analyze_count,
            ut.autoanalyze_count,
                CASE
                    WHEN (c.relkind <> 'p'::"char") THEN age(c.relfrozenxid)
                    ELSE 0
                END AS tx_freeze_age,
            (EXTRACT(epoch FROM (now() - ut.last_seq_scan)))::bigint AS last_seq_scan_s,
            (round((ut.total_vacuum_time)::numeric, 3))::double precision AS total_vacuum_time,
            (round((ut.total_autovacuum_time)::numeric, 3))::double precision AS total_autovacuum_time,
            (round((ut.total_analyze_time)::numeric, 3))::double precision AS total_analyze_time,
            (round((ut.total_autoanalyze_time)::numeric, 3))::double precision AS total_autoanalyze_time
           FROM ((((pg_stat_user_tables ut
             JOIN pg_class c ON ((c.oid = ut.relid)))
             LEFT JOIN pg_class t ON ((t.oid = c.reltoastrelid)))
             LEFT JOIN pg_index ti ON ((ti.indrelid = t.oid)))
             LEFT JOIN pg_class tir ON ((tir.oid = ti.indexrelid)))
          WHERE ((NOT (EXISTS ( SELECT 1
                   FROM pg_locks
                  WHERE ((pg_locks.relation = ut.relid) AND (pg_locks.mode = 'AccessExclusiveLock'::text))))) AND (c.relpersistence <> 't'::"char"))
          ORDER BY
                CASE
                    WHEN (c.relkind = 'p'::"char") THEN ('1000000000'::numeric)::integer
                    ELSE ((COALESCE(c.relpages, 0) + COALESCE(t.relpages, 0)) + COALESCE(tir.relpages, 0))
                END DESC
         LIMIT 1500
        )
 SELECT q_tstats.epoch_ns,
    q_tstats.tag_schema,
    q_tstats.tag_table_name,
    q_tstats.tag_table_full_name,
    0 AS is_part_root,
    q_tstats.table_size_b,
    q_tstats.tag_table_size_cardinality_mb,
    q_tstats.total_relation_size_b,
    q_tstats.toast_size_b,
    q_tstats.seconds_since_last_vacuum,
    q_tstats.seconds_since_last_analyze,
    q_tstats.no_autovacuum,
    q_tstats.seq_scan,
    q_tstats.seq_tup_read,
    q_tstats.idx_scan,
    q_tstats.idx_tup_fetch,
    q_tstats.n_tup_ins,
    q_tstats.n_tup_upd,
    q_tstats.n_tup_del,
    q_tstats.n_tup_hot_upd,
    q_tstats.n_live_tup,
    q_tstats.n_dead_tup,
    q_tstats.vacuum_count,
    q_tstats.autovacuum_count,
    q_tstats.analyze_count,
    q_tstats.autoanalyze_count,
    q_tstats.tx_freeze_age,
    q_tstats.last_seq_scan_s,
    q_tstats.total_vacuum_time,
    q_tstats.total_autovacuum_time,
    q_tstats.total_analyze_time,
    q_tstats.total_autoanalyze_time
   FROM q_tstats
  WHERE ((NOT (q_tstats.tag_schema ~~ '\_timescaledb%'::text)) AND (NOT (EXISTS ( SELECT q_root_part.oid,
            q_root_part.relkind,
            q_root_part.root_schema,
            q_root_part.root_relname
           FROM q_root_part
          WHERE (q_root_part.oid = q_tstats.relid)))))
UNION ALL
 SELECT x.epoch_ns,
    x.tag_schema,
    x.tag_table_name,
    x.tag_table_full_name,
    x.is_part_root,
    x.table_size_b,
    x.tag_table_size_cardinality_mb,
    x.total_relation_size_b,
    x.toast_size_b,
    x.seconds_since_last_vacuum,
    x.seconds_since_last_analyze,
    x.no_autovacuum,
    x.seq_scan,
    x.seq_tup_read,
    x.idx_scan,
    x.idx_tup_fetch,
    x.n_tup_ins,
    x.n_tup_upd,
    x.n_tup_del,
    x.n_tup_hot_upd,
    x.n_live_tup,
    x.n_dead_tup,
    x.vacuum_count,
    x.autovacuum_count,
    x.analyze_count,
    x.autoanalyze_count,
    x.tx_freeze_age,
    x.last_seq_scan_s,
    x.total_vacuum_time,
    x.total_autovacuum_time,
    x.total_analyze_time,
    x.total_autoanalyze_time
   FROM ( SELECT ts.epoch_ns,
            quote_ident((qr.root_schema)::text) AS tag_schema,
            quote_ident((qr.root_relname)::text) AS tag_table_name,
            ((quote_ident((qr.root_schema)::text) || '.'::text) || quote_ident((qr.root_relname)::text)) AS tag_table_full_name,
            1 AS is_part_root,
            (sum(ts.table_size_b))::bigint AS table_size_b,
            (abs(GREATEST(ceil(log((((sum(ts.table_size_b) + (1)::numeric))::double precision / ((10)::double precision ^ (6)::double precision)))), (0)::double precision)))::text AS tag_table_size_cardinality_mb,
            (sum(ts.total_relation_size_b))::bigint AS total_relation_size_b,
            (sum(ts.toast_size_b))::bigint AS toast_size_b,
            min(ts.seconds_since_last_vacuum) AS seconds_since_last_vacuum,
            min(ts.seconds_since_last_analyze) AS seconds_since_last_analyze,
            sum(ts.no_autovacuum) AS no_autovacuum,
            (sum(ts.seq_scan))::bigint AS seq_scan,
            (sum(ts.seq_tup_read))::bigint AS seq_tup_read,
            (sum(ts.idx_scan))::bigint AS idx_scan,
            (sum(ts.idx_tup_fetch))::bigint AS idx_tup_fetch,
            (sum(ts.n_tup_ins))::bigint AS n_tup_ins,
            (sum(ts.n_tup_upd))::bigint AS n_tup_upd,
            (sum(ts.n_tup_del))::bigint AS n_tup_del,
            (sum(ts.n_tup_hot_upd))::bigint AS n_tup_hot_upd,
            (sum(ts.n_live_tup))::bigint AS n_live_tup,
            (sum(ts.n_dead_tup))::bigint AS n_dead_tup,
            (sum(ts.vacuum_count))::bigint AS vacuum_count,
            (sum(ts.autovacuum_count))::bigint AS autovacuum_count,
            (sum(ts.analyze_count))::bigint AS analyze_count,
            (sum(ts.autoanalyze_count))::bigint AS autoanalyze_count,
            (max(ts.tx_freeze_age))::bigint AS tx_freeze_age,
            min(ts.last_seq_scan_s) AS last_seq_scan_s,
            sum(ts.total_vacuum_time) AS total_vacuum_time,
            sum(ts.total_autovacuum_time) AS total_autovacuum_time,
            sum(ts.total_analyze_time) AS total_analyze_time,
            sum(ts.total_autoanalyze_time) AS total_autoanalyze_time
           FROM ((q_tstats ts
             JOIN q_parts qp ON ((qp.relid = ts.relid)))
             JOIN q_root_part qr ON ((qr.oid = qp.root)))
          GROUP BY ts.epoch_ns, (quote_ident((qr.root_schema)::text)), (quote_ident((qr.root_relname)::text)), ((quote_ident((qr.root_schema)::text) || '.'::text) || quote_ident((qr.root_relname)::text))) x
  ORDER BY 6 DESC NULLS LAST
 LIMIT 300;


ALTER VIEW public.v_pgwatch_table_stats OWNER TO d3l243;

--
-- Name: VIEW v_pgwatch_table_stats; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_pgwatch_table_stats IS 'This query is defined in file pgwatch/internal/metrics/metrics.yaml; see https://github.com/cybertec-postgresql/pgwatch/blob/7af5f45f5e89d06517b4ea2392619a85100b8ffe/internal/metrics/metrics.yaml#L3624';

--
-- Name: TABLE v_pgwatch_table_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_pgwatch_table_stats TO readaccess;
GRANT SELECT ON TABLE public.v_pgwatch_table_stats TO writeaccess;

