--
-- Name: v_mts_pt_dbs_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mts_pt_dbs_detail_report AS
 SELECT ptdbs.peptide_db_name,
    ptdbs.peptide_db_id,
    ptdbs.description,
    ptdbs.organism,
    ptdbs.msms_jobs,
    ptdbs.sic_jobs,
    public.get_mtdbs_for_peptide_db((ptdbs.peptide_db_name)::text) AS mass_tag_dbs,
    ptdbs.server_name,
    ptdbs.state,
    ptdbs.state_id,
    ptdbs.last_affected
   FROM public.t_mts_pt_dbs_cached ptdbs;


ALTER TABLE public.v_mts_pt_dbs_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_mts_pt_dbs_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mts_pt_dbs_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_mts_pt_dbs_detail_report TO writeaccess;

