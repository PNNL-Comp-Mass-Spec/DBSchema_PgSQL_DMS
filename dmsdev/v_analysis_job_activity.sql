--
-- Name: v_analysis_job_activity; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_activity AS
 SELECT filterq.batch_id AS batch,
    filterq.job,
    COALESCE(ajpg.group_name, ''::public.citext) AS proc_group,
    filterq.dataset,
    filterq.priority,
    filterq.job_state_id AS state,
    filterq.job_state AS state_name,
    filterq.analysis_tool AS tool,
    filterq.param_file_name AS param_file,
    filterq.protein_collection_list AS protein_collection,
    filterq.protein_options_list AS protein_options,
    COALESCE(filterq.work_package, ''::public.citext) AS work_pkg,
    filterq.created
   FROM ((public.t_analysis_job_processor_group_associations ajpga
     JOIN public.t_analysis_job_processor_group ajpg ON ((ajpga.group_id = ajpg.group_id)))
     RIGHT JOIN ( SELECT j.batch_id,
            j.job,
            ds.dataset,
            j.priority,
            j.job_state_id,
            js.job_state,
            tool.analysis_tool,
            j.param_file_name,
            j.protein_collection_list,
            j.protein_options_list,
            ajr.work_package,
            j.created
           FROM ((((public.t_analysis_job j
             JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
             JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
             JOIN public.t_analysis_job_request ajr ON ((j.request_id = ajr.request_id)))
             JOIN public.t_analysis_job_state js ON ((j.job_state_id = js.job_state_id)))
          WHERE ((tool.analysis_tool_id IN ( SELECT t_analysis_tool.analysis_tool_id
                   FROM public.t_analysis_tool
                  WHERE (t_analysis_tool.active <> 0))) AND ((j.job_state_id = ANY (ARRAY[1, 2, 8])) OR ((j.job_state_id = 5) AND (j.start > (CURRENT_TIMESTAMP - '14 days'::interval)))))
          GROUP BY j.job, tool.analysis_tool, tool.analysis_tool_id, j.batch_id, ds.dataset, j.param_file_name, j.protein_collection_list, j.protein_options_list, ajr.work_package, j.priority, j.job_state_id, j.created, js.job_state) filterq ON ((ajpga.job = filterq.job)));


ALTER VIEW public.v_analysis_job_activity OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_activity; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_activity TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_activity TO writeaccess;

