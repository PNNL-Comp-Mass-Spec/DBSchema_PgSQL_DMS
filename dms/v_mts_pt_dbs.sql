--
-- Name: v_mts_pt_dbs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mts_pt_dbs AS
 SELECT ptdbs.peptide_db_id,
    ptdbs.peptide_db_name,
    ptdbs.state,
    ptdbs.description,
    ptdbs.organism,
    ptdbs.msms_jobs,
    ptdbs.sic_jobs,
    ptdbs.server_name,
    ptdbs.state_id
   FROM public.t_mts_pt_dbs_cached ptdbs;


ALTER VIEW public.v_mts_pt_dbs OWNER TO d3l243;

--
-- Name: TABLE v_mts_pt_dbs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mts_pt_dbs TO readaccess;
GRANT SELECT ON TABLE public.v_mts_pt_dbs TO writeaccess;

