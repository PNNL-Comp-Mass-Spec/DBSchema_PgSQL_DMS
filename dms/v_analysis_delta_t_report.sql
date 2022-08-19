--
-- Name: v_analysis_delta_t_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_delta_t_report AS
 SELECT j.job,
    (EXTRACT(epoch FROM (j.finish - j.start)) / 60.0) AS delta_t,
    j.priority AS pri,
    js.job_state AS state,
    tool.analysis_tool AS tool_name,
    ds.dataset,
    j.param_file_name AS param_file,
    j.settings_file_name AS settings_file,
    org.organism,
    j.organism_db_name AS organism_db,
    j.protein_collection_list,
    j.protein_options_list AS protein_options,
    j.comment,
    j.created,
    j.start AS started,
    j.finish AS finished,
    COALESCE(j.assigned_processor_name, '(none)'::public.citext) AS cpu,
    COALESCE(j.results_folder_name, '(none)'::public.citext) AS results_folder
   FROM ((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms org ON ((j.organism_id = org.organism_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_analysis_job_state js ON ((j.job_state_id = js.job_state_id)));


ALTER TABLE public.v_analysis_delta_t_report OWNER TO d3l243;

--
-- Name: VIEW v_analysis_delta_t_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_analysis_delta_t_report IS 'V_Analysis_DeltaT_Report';

--
-- Name: TABLE v_analysis_delta_t_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_delta_t_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_delta_t_report TO writeaccess;

