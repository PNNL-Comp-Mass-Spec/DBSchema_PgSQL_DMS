--
-- Name: v_mt_dbs; Type: VIEW; Schema: mts; Owner: d3l243
--

CREATE VIEW mts.v_mt_dbs AS
 SELECT v_mts_mt_dbs.server_name,
    v_mts_mt_dbs.mt_db_id,
    v_mts_mt_dbs.mt_db_name,
    v_mts_mt_dbs.state_id,
    v_mts_mt_dbs.state,
    v_mts_mt_dbs.last_affected,
    v_mts_mt_dbs.last_online,
    v_mts_mt_dbs.description,
    v_mts_mt_dbs.organism,
    v_mts_mt_dbs.campaign,
    v_mts_mt_dbs.db_schema_version,
    v_mts_mt_dbs.peptide_db,
    v_mts_mt_dbs.peptide_db_count
   FROM mts.v_mts_mt_dbs
  WHERE ((v_mts_mt_dbs.server_active = 1) AND (v_mts_mt_dbs.state_id < 15))
UNION
 SELECT v_mts_mt_dbs.server_name,
    v_mts_mt_dbs.mt_db_id,
    v_mts_mt_dbs.mt_db_name,
    v_mts_mt_dbs.state_id,
    v_mts_mt_dbs.state,
    v_mts_mt_dbs.last_affected,
    v_mts_mt_dbs.last_online,
    v_mts_mt_dbs.description,
    v_mts_mt_dbs.organism,
    v_mts_mt_dbs.campaign,
    v_mts_mt_dbs.db_schema_version,
    v_mts_mt_dbs.peptide_db,
    v_mts_mt_dbs.peptide_db_count
   FROM mts.v_mts_mt_dbs
  WHERE ((((v_mts_mt_dbs.server_active = 1) AND (v_mts_mt_dbs.state_id >= 15)) OR (v_mts_mt_dbs.server_active = 0)) AND (NOT (v_mts_mt_dbs.mt_db_name OPERATOR(public.=) ANY ( SELECT v_mts_mt_dbs_1.mt_db_name
           FROM mts.v_mts_mt_dbs v_mts_mt_dbs_1
          WHERE ((v_mts_mt_dbs_1.server_active = 1) AND (v_mts_mt_dbs_1.state_id < 15))))));


ALTER VIEW mts.v_mt_dbs OWNER TO d3l243;

--
-- Name: TABLE v_mt_dbs; Type: ACL; Schema: mts; Owner: d3l243
--

GRANT SELECT ON TABLE mts.v_mt_dbs TO readaccess;
GRANT SELECT ON TABLE mts.v_mt_dbs TO writeaccess;

