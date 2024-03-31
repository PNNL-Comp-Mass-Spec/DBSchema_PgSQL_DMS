--
-- Name: v_mts_pt_dbs_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mts_pt_dbs_detail_report AS
 SELECT peptide_db_name,
    peptide_db_id,
    description,
    organism,
    msms_jobs,
    sic_jobs,
    public.get_mtdbs_for_peptide_db((peptide_db_name)::text) AS mass_tag_dbs,
    server_name,
    state,
    state_id,
    last_affected
   FROM public.t_mts_pt_dbs_cached ptdbs;


ALTER VIEW public.v_mts_pt_dbs_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_mts_pt_dbs_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mts_pt_dbs_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_mts_pt_dbs_detail_report TO writeaccess;

