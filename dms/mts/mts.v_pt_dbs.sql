--
-- Name: v_pt_dbs; Type: VIEW; Schema: mts; Owner: d3l243
--

CREATE VIEW mts.v_pt_dbs AS
 SELECT v_mts_peptide_dbs.server_name,
    v_mts_peptide_dbs.peptide_db_id,
    v_mts_peptide_dbs.peptide_db_name,
    v_mts_peptide_dbs.state_id,
    v_mts_peptide_dbs.state,
    v_mts_peptide_dbs.last_affected,
    v_mts_peptide_dbs.last_online,
    v_mts_peptide_dbs.description,
    v_mts_peptide_dbs.organism,
    v_mts_peptide_dbs.db_schema_version
   FROM mts.v_mts_peptide_dbs
  WHERE ((v_mts_peptide_dbs.server_active = 1) AND (v_mts_peptide_dbs.state_id < 15))
UNION
 SELECT v_mts_peptide_dbs.server_name,
    v_mts_peptide_dbs.peptide_db_id,
    v_mts_peptide_dbs.peptide_db_name,
    v_mts_peptide_dbs.state_id,
    v_mts_peptide_dbs.state,
    v_mts_peptide_dbs.last_affected,
    v_mts_peptide_dbs.last_online,
    v_mts_peptide_dbs.description,
    v_mts_peptide_dbs.organism,
    v_mts_peptide_dbs.db_schema_version
   FROM mts.v_mts_peptide_dbs
  WHERE ((((v_mts_peptide_dbs.server_active = 1) AND (v_mts_peptide_dbs.state_id >= 15)) OR (v_mts_peptide_dbs.server_active = 0)) AND (NOT (v_mts_peptide_dbs.peptide_db_name OPERATOR(public.=) ANY ( SELECT v_mts_peptide_dbs_1.peptide_db_name
           FROM mts.v_mts_peptide_dbs v_mts_peptide_dbs_1
          WHERE ((v_mts_peptide_dbs_1.server_active = 1) AND (v_mts_peptide_dbs_1.state_id < 15))))));


ALTER VIEW mts.v_pt_dbs OWNER TO d3l243;

--
-- Name: TABLE v_pt_dbs; Type: ACL; Schema: mts; Owner: d3l243
--

GRANT SELECT ON TABLE mts.v_pt_dbs TO readaccess;
GRANT SELECT ON TABLE mts.v_pt_dbs TO writeaccess;

