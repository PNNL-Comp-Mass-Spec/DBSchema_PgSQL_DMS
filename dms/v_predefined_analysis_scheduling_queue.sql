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
    count(aj.job) AS jobs,
    public.min(aj.tool) AS tool_first,
    public.max(aj.tool) AS tool_last,
    min(aj.started) AS started_first,
    max(aj.started) AS started_last,
    sum(aj.runtime) AS total_runtime
   FROM (public.t_predefined_analysis_scheduling_queue sq
     LEFT JOIN (( SELECT aj_1.job,
            antool.analysis_tool AS tool,
            aj_1.start AS started,
            aj_1.processing_time_minutes AS runtime,
            aj_1.dataset_id
           FROM (public.t_analysis_job aj_1
             JOIN public.t_analysis_tool antool ON ((aj_1.analysis_tool_id = antool.analysis_tool_id)))) aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id))) ON ((sq.dataset_id = ds.dataset_id)))
  GROUP BY sq.item, sq.dataset_id, ds.dataset, sq.calling_user, sq.analysis_tool_name_filter, sq.exclude_datasets_not_released, sq.prevent_duplicate_jobs, sq.state, sq.result_code, sq.message, sq.jobs_created, sq.entered, sq.last_affected;


ALTER TABLE public.v_predefined_analysis_scheduling_queue OWNER TO d3l243;

--
-- Name: TABLE v_predefined_analysis_scheduling_queue; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_analysis_scheduling_queue TO readaccess;

