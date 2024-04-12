--
-- Name: v_analysis_job_check_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_check_report AS
 SELECT j.job,
    js.job_state AS state,
    j.start AS started,
    j.finish AS finished,
    COALESCE(j.assigned_processor_name, '(none)'::public.citext) AS cpu,
    tool.analysis_tool AS tool_name,
    ds.dataset,
    j.comment,
    j.priority,
    spath.machine_name AS storage,
    spath.storage_path AS path,
    j.param_file_name AS param_file,
    j.settings_file_name AS settings_file,
    j.organism_db_name AS organism_db,
    j.protein_collection_list,
    j.protein_options_list AS protein_options,
    COALESCE(j.results_folder_name, '(none)'::public.citext) AS results_folder,
    j.batch_id AS batch,
    org.organism,
        CASE
            WHEN ((j.job_state_id = 2) AND (j.start > (CURRENT_TIMESTAMP - '6 mons'::interval))) THEN (EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (j.start)::timestamp with time zone)) / (3600)::numeric)
            WHEN (j.job_state_id = 5) THEN (EXTRACT(epoch FROM (j.finish - j.start)) / (3600)::numeric)
            ELSE NULL::numeric
        END AS elapsed_hours
   FROM (((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms org ON ((j.organism_id = org.organism_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_analysis_job_state js ON ((j.job_state_id = js.job_state_id)))
  WHERE (j.job_state_id = ANY (ARRAY[2, 3, 5, 19]));


ALTER VIEW public.v_analysis_job_check_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_check_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_check_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_check_report TO writeaccess;

