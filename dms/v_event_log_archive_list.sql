--
-- Name: v_event_log_archive_list; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_event_log_archive_list AS
 SELECT el.event_id,
    el.target_id AS dataset_id,
    t_dataset.dataset,
    oldstate.archive_state AS old_state,
    newstate.archive_state AS new_state,
    el.entered AS date
   FROM (((public.t_event_log el
     JOIN public.t_dataset ON ((el.target_id = t_dataset.dataset_id)))
     JOIN public.t_dataset_archive_state_name newstate ON ((el.target_state = newstate.archive_state_id)))
     JOIN public.t_dataset_archive_state_name oldstate ON ((el.prev_target_state = oldstate.archive_state_id)))
  WHERE ((el.target_type = 6) AND (el.entered >= (CURRENT_TIMESTAMP - '4 days'::interval)));


ALTER TABLE public.v_event_log_archive_list OWNER TO d3l243;

--
-- Name: TABLE v_event_log_archive_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_event_log_archive_list TO readaccess;

