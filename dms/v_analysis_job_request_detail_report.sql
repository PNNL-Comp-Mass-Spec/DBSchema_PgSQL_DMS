--
-- Name: v_analysis_job_request_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_request_detail_report AS
 SELECT ajr.request_id AS request,
    ajr.request_name AS name,
    ajr.created,
    ajr.analysis_tool AS tool,
    ajr.param_file_name AS parameter_file,
    ajr.settings_file_name AS settings_file,
    org.organism,
    ajr.protein_collection_list,
    ajr.protein_options_list AS protein_options,
    ajr.organism_db_name AS organism_db_file,
    public.get_job_request_dataset_name_list(ajr.request_id) AS datasets,
    ajr.data_pkg_id AS data_package_id,
    ajr.comment,
    ajr.special_processing,
    u.name AS requester_name,
    u.username AS requester,
    ars.request_state AS state,
    ajr.max_active_jobs,
    public.get_job_request_instrument_list(ajr.request_id) AS instruments,
    public.get_job_request_existing_job_list(ajr.request_id) AS pre_existing_jobs,
    COALESCE(jobsq.jobs, (0)::bigint) AS jobs
   FROM ((((public.t_analysis_job_request ajr
     JOIN public.t_users u ON ((ajr.user_id = u.user_id)))
     JOIN public.t_analysis_job_request_state ars ON ((ajr.request_state_id = ars.request_state_id)))
     JOIN public.t_organisms org ON ((ajr.organism_id = org.organism_id)))
     LEFT JOIN ( SELECT j.request_id,
            count(j.job) AS jobs
           FROM public.t_analysis_job j
          GROUP BY j.request_id) jobsq ON ((ajr.request_id = jobsq.request_id)));


ALTER VIEW public.v_analysis_job_request_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_request_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_request_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_request_detail_report TO writeaccess;

