--
-- Name: v_tracking_dataset_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_tracking_dataset_entry AS
 SELECT ds.dataset,
    e.experiment,
    ds.operator_username,
    instname.instrument AS instrument_name,
    ds.acq_time_start AS run_start,
    ds.acq_length_minutes AS run_duration,
    ds.comment,
    eut.eus_usage_type,
    rr.eus_proposal_id,
    public.get_requested_run_eus_users_list(rr.request_id, 'I'::text) AS eus_users_list
   FROM ((((public.t_dataset ds
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_requested_run rr ON ((rr.dataset_id = ds.dataset_id)))
     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)));


ALTER TABLE public.v_tracking_dataset_entry OWNER TO d3l243;

--
-- Name: TABLE v_tracking_dataset_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_tracking_dataset_entry TO readaccess;
GRANT SELECT ON TABLE public.v_tracking_dataset_entry TO writeaccess;

