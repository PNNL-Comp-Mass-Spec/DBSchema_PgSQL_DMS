--
-- Name: v_analysis_job_duration_precise; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_duration_precise AS
 SELECT startq.job,
    startq.entered AS job_start,
    endq.entered AS job_finish,
    j.processing_time_minutes AS job_length_minutes,
    (EXTRACT(epoch FROM (endq.entered - startq.entered)) / (60)::numeric) AS active_queue_time_minutes
   FROM ((( SELECT t_event_log.target_id AS job,
            max(t_event_log.entered) AS entered
           FROM public.t_event_log
          WHERE ((t_event_log.target_type = 5) AND (t_event_log.target_state = 2))
          GROUP BY t_event_log.target_id) startq
     JOIN public.t_analysis_job j ON ((startq.job = j.job)))
     LEFT JOIN ( SELECT t_event_log.target_id AS job,
            max(t_event_log.entered) AS entered
           FROM public.t_event_log
          WHERE ((t_event_log.target_type = 5) AND (t_event_log.prev_target_state = 2) AND (t_event_log.target_state <> ALL (ARRAY[1, 2, 8])))
          GROUP BY t_event_log.target_id) endq ON (((startq.job = endq.job) AND (startq.entered < endq.entered))));


ALTER VIEW public.v_analysis_job_duration_precise OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_duration_precise; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_duration_precise TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_duration_precise TO writeaccess;

