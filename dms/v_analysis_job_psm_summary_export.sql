--
-- Name: v_analysis_job_psm_summary_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_psm_summary_export AS
 SELECT j.dataset_id,
    count(*) AS jobs,
    COALESCE(max(psm.total_psms_fdr_filter), max(psm.total_psms)) AS max_total_psms,
    COALESCE(max(psm.unique_peptides_fdr_filter), max(psm.unique_peptides)) AS max_unique_peptides,
    COALESCE(max(psm.unique_proteins_fdr_filter), max(psm.unique_proteins)) AS max_unique_proteins,
    max(psm.total_psms) AS max_total_psms_msgf,
    max(psm.unique_peptides) AS max_unique_peptides_msgf,
    max(psm.unique_proteins) AS max_unique_proteins_msgf,
    max(psm.total_psms_fdr_filter) AS max_total_psms_fdr_filter,
    max(psm.unique_peptides_fdr_filter) AS max_unique_peptides_fdr_filter,
    max(psm.unique_proteins_fdr_filter) AS max_unique_proteins_fdr_filter
   FROM (public.t_analysis_job j
     JOIN public.t_analysis_job_psm_stats psm ON ((j.job = psm.job)))
  WHERE (j.analysis_tool_id IN ( SELECT t_analysis_tool.analysis_tool_id
           FROM public.t_analysis_tool
          WHERE ((t_analysis_tool.result_type OPERATOR(public.~~) '%peptide_hit'::public.citext) OR (t_analysis_tool.result_type OPERATOR(public.=) 'Gly_ID'::public.citext))))
  GROUP BY j.dataset_id;


ALTER TABLE public.v_analysis_job_psm_summary_export OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_psm_summary_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_psm_summary_export TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_psm_summary_export TO writeaccess;

