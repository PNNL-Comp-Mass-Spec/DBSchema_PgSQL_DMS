--
-- Name: v_data_package_analysis_jobs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_package_analysis_jobs AS
 SELECT dpj.data_package_id,
    dpj.job,
    dpj.dataset,
    j.dataset_id,
    dpj.tool,
    dpj.package_comment,
    dpj.item_added,
    mj.folder
   FROM ((public.t_analysis_job j
     JOIN dpkg.v_data_package_analysis_jobs_export dpj ON ((j.job = dpj.job)))
     JOIN public.v_mage_analysis_jobs mj ON ((j.job = mj.job)));


ALTER TABLE public.v_data_package_analysis_jobs OWNER TO d3l243;

--
-- Name: TABLE v_data_package_analysis_jobs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_package_analysis_jobs TO readaccess;
GRANT SELECT ON TABLE public.v_data_package_analysis_jobs TO writeaccess;

