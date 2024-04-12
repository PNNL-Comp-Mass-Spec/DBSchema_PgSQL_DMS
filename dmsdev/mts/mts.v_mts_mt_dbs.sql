--
-- Name: v_mts_mt_dbs; Type: VIEW; Schema: mts; Owner: d3l243
--

CREATE VIEW mts.v_mts_mt_dbs AS
 SELECT m.mt_db_id,
    m.mt_db_name,
    s.server_name,
    m.state_id,
    dbstates.state_name AS state,
    m.last_affected,
    m.last_online,
    m.description,
    m.organism,
    m.campaign,
    m.db_schema_version,
    m.comment,
    m.created,
    s.active AS server_active,
    pdm.peptide_db,
    pdbc.peptide_db_count
   FROM ((((mts.t_mt_dbs m
     JOIN mts.t_mts_servers s ON ((m.server_id = s.server_id)))
     LEFT JOIN mts.t_mt_database_state_name dbstates ON ((m.state_id = dbstates.state_id)))
     LEFT JOIN mts.v_mts_mtdb_to_peptidedb_map pdm ON (((m.mt_db_name OPERATOR(public.=) pdm.mt_db_name) AND (COALESCE(pdm.peptide_db_num, (1)::bigint) = 1))))
     LEFT JOIN ( SELECT v_mts_mtdb_to_peptidedb_map.mt_db_name,
            count(*) AS peptide_db_count
           FROM mts.v_mts_mtdb_to_peptidedb_map
          WHERE (NOT (v_mts_mtdb_to_peptidedb_map.peptide_db IS NULL))
          GROUP BY v_mts_mtdb_to_peptidedb_map.mt_db_name) pdbc ON ((m.mt_db_name OPERATOR(public.=) pdbc.mt_db_name)));


ALTER VIEW mts.v_mts_mt_dbs OWNER TO d3l243;

--
-- Name: TABLE v_mts_mt_dbs; Type: ACL; Schema: mts; Owner: d3l243
--

GRANT SELECT ON TABLE mts.v_mts_mt_dbs TO readaccess;
GRANT SELECT ON TABLE mts.v_mts_mt_dbs TO writeaccess;

