--
-- Name: v_predefined_analysis_scheduling_queue; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_predefined_analysis_scheduling_queue AS
 SELECT sq.item,
    sq.dataset_id,
    ds.dataset,
    sq.calling_user,
    sq.analysis_tool_name_filter,
    sq.exclude_datasets_not_released,
    sq.prevent_duplicate_jobs,
    sq.state,
    sq.result_code,
    sq.message,
    sq.jobs_created,
    sq.entered,
    sq.last_affected,
    count(j.job) AS jobs,
    public.min(j.tool) AS tool_first,
    public.max(j.tool) AS tool_last,
    min(j.started) AS started_first,
    max(j.started) AS started_last,
    sum(j.runtime) AS total_runtime
   FROM (public.t_predefined_analysis_scheduling_queue sq
     LEFT JOIN (( SELECT aj.job,
            antool.analysis_tool AS tool,
            aj.start AS started,
            aj.processing_time_minutes AS runtime,
            aj.dataset_id
           FROM (public.t_analysis_job aj
             JOIN public.t_analysis_tool antool ON ((aj.analysis_tool_id = antool.analysis_tool_id)))) j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id))) ON ((sq.dataset_id = ds.dataset_id)))
  GROUP BY sq.item, sq.dataset_id, ds.dataset, sq.calling_user, sq.analysis_tool_name_filter, sq.exclude_datasets_not_released, sq.prevent_duplicate_jobs, sq.state, sq.result_code, sq.message, sq.jobs_created, sq.entered, sq.last_affected;


ALTER VIEW public.v_predefined_analysis_scheduling_queue OWNER TO d3l243;

--
-- Name: TABLE v_predefined_analysis_scheduling_queue; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_analysis_scheduling_queue TO readaccess;
GRANT SELECT ON TABLE public.v_predefined_analysis_scheduling_queue TO writeaccess;

