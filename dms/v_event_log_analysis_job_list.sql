--
-- Name: v_event_log_analysis_job_list; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_event_log_analysis_job_list AS
 SELECT el.event_id,
    el.target_id AS job,
    t_dataset.dataset,
    oldstate.job_state AS old_state,
    newstate.job_state AS new_state,
    el.entered AS date
   FROM ((((public.t_event_log el
     JOIN public.t_analysis_job_state newstate ON ((el.target_state = newstate.job_state_id)))
     JOIN public.t_analysis_job_state oldstate ON ((el.prev_target_state = oldstate.job_state_id)))
     JOIN public.t_analysis_job ON ((el.target_id = t_analysis_job.job)))
     JOIN public.t_dataset ON ((t_analysis_job.dataset_id = t_dataset.dataset_id)))
  WHERE ((el.target_type = 5) AND (el.entered >= (CURRENT_TIMESTAMP - '4 days'::interval)));


ALTER TABLE public.v_event_log_analysis_job_list OWNER TO d3l243;

--
-- Name: TABLE v_event_log_analysis_job_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_event_log_analysis_job_list TO readaccess;

