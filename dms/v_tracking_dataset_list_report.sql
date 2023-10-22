--
-- Name: v_tracking_dataset_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_tracking_dataset_list_report AS
 SELECT ds.dataset,
    instname.instrument,
    EXTRACT(month FROM ds.acq_time_start) AS month,
    EXTRACT(day FROM ds.acq_time_start) AS day,
    ds.acq_time_start AS start,
    ds.acq_length_minutes AS duration,
    e.experiment,
    u.name_with_username AS operator,
    ds.comment,
    eut.eus_usage_type AS emsl_usage_type,
    rr.eus_proposal_id AS emsl_proposal_id,
    (public.get_requested_run_eus_users_list(rr.request_id, 'I'::text))::public.citext AS emsl_users_list
   FROM ((((((public.t_dataset ds
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_requested_run rr ON ((rr.dataset_id = ds.dataset_id)))
     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     LEFT JOIN public.t_users u ON ((ds.operator_username OPERATOR(public.=) u.username)))
  WHERE (dtn.dataset_type OPERATOR(public.=) 'Tracking'::public.citext);


ALTER TABLE public.v_tracking_dataset_list_report OWNER TO d3l243;

--
-- Name: TABLE v_tracking_dataset_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_tracking_dataset_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_tracking_dataset_list_report TO writeaccess;

