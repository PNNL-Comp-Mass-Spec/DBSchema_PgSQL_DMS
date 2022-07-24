--
-- Name: v_predefined_analysis_scheduling_queue_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_predefined_analysis_scheduling_queue_list_report AS
 SELECT sq.item,
    d.dataset,
    sq.dataset_id AS id,
    sq.calling_user AS "user",
    sq.state,
    sq.result_code,
    sq.message,
    sq.entered,
    sq.last_affected,
    sq.jobs_created,
    sq.analysis_tool_name_filter AS analysis_tool_filter,
    sq.exclude_datasets_not_released AS exclude_dataset_not_released,
    sq.prevent_duplicate_jobs
   FROM (public.t_predefined_analysis_scheduling_queue sq
     JOIN public.t_dataset d ON ((sq.dataset_id = d.dataset_id)));


ALTER TABLE public.v_predefined_analysis_scheduling_queue_list_report OWNER TO d3l243;

--
-- Name: TABLE v_predefined_analysis_scheduling_queue_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_analysis_scheduling_queue_list_report TO readaccess;

