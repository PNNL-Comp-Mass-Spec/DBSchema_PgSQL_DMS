--
-- Name: v_event_log_dataset_list; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_event_log_dataset_list AS
 SELECT el.event_id,
    el.target_id AS dataset_id,
    t_dataset.dataset,
    oldstate.dataset_state AS old_state,
    newstate.dataset_state AS new_state,
    el.entered AS date,
    t_instrument_name.instrument
   FROM ((((public.t_event_log el
     JOIN public.t_dataset ON ((el.target_id = t_dataset.dataset_id)))
     JOIN public.t_dataset_state_name newstate ON ((el.target_state = newstate.dataset_state_id)))
     JOIN public.t_dataset_state_name oldstate ON ((el.prev_target_state = oldstate.dataset_state_id)))
     JOIN public.t_instrument_name ON ((t_dataset.instrument_id = t_instrument_name.instrument_id)))
  WHERE ((el.target_type = 4) AND (el.entered >= (CURRENT_TIMESTAMP - '4 days'::interval)));


ALTER VIEW public.v_event_log_dataset_list OWNER TO d3l243;

--
-- Name: TABLE v_event_log_dataset_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_event_log_dataset_list TO readaccess;
GRANT SELECT ON TABLE public.v_event_log_dataset_list TO writeaccess;

