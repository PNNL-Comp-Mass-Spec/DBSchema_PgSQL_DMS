--
-- Name: v_mts_peptide_dbs; Type: VIEW; Schema: mts; Owner: d3l243
--

CREATE VIEW mts.v_mts_peptide_dbs AS
 SELECT p.peptide_db_id,
    p.peptide_db_name,
    s.server_name,
    p.state_id,
    dbstates.state_name AS state,
    p.last_affected,
    p.last_online,
    p.description,
    p.organism,
    p.db_schema_version,
    p.comment,
    p.created,
    s.active AS server_active
   FROM ((mts.t_pt_dbs p
     JOIN mts.t_mt_database_state_name dbstates ON ((p.state_id = dbstates.state_id)))
     JOIN mts.t_mts_servers s ON ((p.server_id = s.server_id)));


ALTER VIEW mts.v_mts_peptide_dbs OWNER TO d3l243;

