--
-- Name: v_analysis_job_activity; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_activity AS
 SELECT j.batch_id AS batch,
    j.job,
    COALESCE(ajpg.group_name, ''::public.citext) AS proc_group,
    j.dataset,
    j.priority,
    j.job_state_id AS state,
    j.job_state AS state_name,
    j.analysis_tool AS tool,
    j.param_file_name AS param_file,
    j.protein_collection_list AS protein_collection,
    j.protein_options_list AS protein_options,
    COALESCE(j.work_package, ''::public.citext) AS work_pkg,
    j.created
   FROM ((public.t_analysis_job_processor_group_associations ajpga
     JOIN public.t_analysis_job_processor_group ajpg ON ((ajpga.group_id = ajpg.group_id)))
     RIGHT JOIN ( SELECT aj.batch_id,
            aj.job,
            ds.dataset,
            aj.priority,
            aj.job_state_id,
            asn.job_state,
            tool.analysis_tool,
            aj.param_file_name,
            aj.protein_collection_list,
            aj.protein_options_list,
            ajr.work_package,
            aj.created
           FROM ((((public.t_analysis_job aj
             JOIN public.t_analysis_tool tool ON ((aj.analysis_tool_id = tool.analysis_tool_id)))
             JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
             JOIN public.t_analysis_job_request ajr ON ((aj.request_id = ajr.request_id)))
             JOIN public.t_analysis_job_state asn ON ((aj.job_state_id = asn.job_state_id)))
          WHERE ((tool.analysis_tool_id IN ( SELECT t_analysis_tool.analysis_tool_id
                   FROM public.t_analysis_tool
                  WHERE (t_analysis_tool.active <> 0))) AND ((aj.job_state_id = ANY (ARRAY[1, 2, 8])) OR ((aj.job_state_id = 5) AND (aj.start > (CURRENT_TIMESTAMP - '14 days'::interval)))))
          GROUP BY aj.job, tool.analysis_tool, tool.analysis_tool_id, aj.batch_id, ds.dataset, aj.param_file_name, aj.protein_collection_list, aj.protein_options_list, ajr.work_package, aj.priority, aj.job_state_id, aj.created, asn.job_state) j ON ((ajpga.job = j.job)));


ALTER TABLE public.v_analysis_job_activity OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_activity; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_activity TO readaccess;

