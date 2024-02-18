--
-- Name: v_mts_mtdb_to_peptidedb_map; Type: VIEW; Schema: mts; Owner: d3l243
--

CREATE VIEW mts.v_mts_mtdb_to_peptidedb_map AS
 SELECT m.mt_db_id,
    m.mt_db_name,
    s.server_name,
    gsc.value AS peptide_db,
    row_number() OVER (PARTITION BY m.mt_db_id, m.mt_db_name, s.server_name ORDER BY gsc.value) AS peptide_db_num
   FROM (((mts.t_mt_dbs m
     JOIN mts.t_mts_servers s ON ((m.server_id = s.server_id)))
     LEFT JOIN mts.t_mt_database_state_name dbstates ON ((m.state_id = dbstates.state_id)))
     LEFT JOIN mts.t_general_statistics_cached gsc ON (((m.mt_db_name OPERATOR(public.=) gsc.db_name) AND (gsc.label OPERATOR(public.=) 'Peptide_DB_Name'::public.citext))));


ALTER VIEW mts.v_mts_mtdb_to_peptidedb_map OWNER TO d3l243;

