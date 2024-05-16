--
-- Name: v_analysis_job_psm_summary_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_psm_summary_export AS
 SELECT dataset_id,
    psm_job_count AS jobs,
    max_total_psms,
    max_unique_peptides,
    max_unique_proteins,
    max_total_psms_fdr_filter,
    max_unique_peptides_fdr_filter,
    max_unique_proteins_fdr_filter
   FROM public.t_cached_dataset_stats cds;


ALTER VIEW public.v_analysis_job_psm_summary_export OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_psm_summary_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_psm_summary_export TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_psm_summary_export TO writeaccess;

