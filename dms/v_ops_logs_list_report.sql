--
-- Name: v_ops_logs_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_ops_logs_list_report AS
 SELECT t_instrument_operation_history.entered,
    t_instrument_operation_history.entered_by,
    t_instrument_operation_history.instrument,
    'Operation'::text AS type,
    ''::text AS id,
    (t_instrument_operation_history.entry_id)::text AS log,
    NULL::integer AS minutes,
    t_instrument_operation_history.note,
    0 AS request,
    ''::text AS usage,
    ''::text AS proposal,
    ''::text AS emsl_user,
    EXTRACT(year FROM t_instrument_operation_history.entered) AS year,
    EXTRACT(month FROM t_instrument_operation_history.entered) AS month,
    EXTRACT(day FROM t_instrument_operation_history.entered) AS day
   FROM public.t_instrument_operation_history
UNION
 SELECT t_instrument_config_history.date_of_change AS entered,
    t_instrument_config_history.entered_by,
    t_instrument_config_history.instrument,
    'Configuration'::text AS type,
    ''::text AS id,
    (t_instrument_config_history.entry_id)::text AS log,
    NULL::integer AS minutes,
    t_instrument_config_history.description AS note,
    0 AS request,
    ''::text AS usage,
    ''::text AS proposal,
    ''::text AS emsl_user,
    EXTRACT(year FROM t_instrument_config_history.entered) AS year,
    EXTRACT(month FROM t_instrument_config_history.entered) AS month,
    EXTRACT(day FROM t_instrument_config_history.entered) AS day
   FROM public.t_instrument_config_history
UNION
 SELECT t_run_interval.start AS entered,
    ''::public.citext AS entered_by,
    t_run_interval.instrument,
    'Long Interval'::text AS type,
    (t_run_interval.interval_id)::text AS id,
    ''::text AS log,
    t_run_interval."interval" AS minutes,
    COALESCE(t_run_interval.comment, ''::public.citext) AS note,
    0 AS request,
    ''::text AS usage,
    ''::text AS proposal,
    ''::text AS emsl_user,
    EXTRACT(year FROM t_run_interval.start) AS year,
    EXTRACT(month FROM t_run_interval.start) AS month,
    EXTRACT(day FROM t_run_interval.start) AS day
   FROM public.t_run_interval
UNION
 SELECT ds.acq_time_start AS entered,
    ds.operator_prn AS entered_by,
    t_instrument_name.instrument,
    'Dataset'::text AS type,
    ''::text AS id,
    ''::text AS log,
    ds.acq_length_minutes AS minutes,
    ds.dataset AS note,
    rr.request_id AS request,
    eut.eus_usage_type AS usage,
    rr.eus_proposal_id AS proposal,
    public.get_requested_run_eus_users_list(rr.request_id, 'I'::text) AS emsl_user,
    EXTRACT(year FROM ds.acq_time_start) AS year,
    EXTRACT(month FROM ds.acq_time_start) AS month,
    EXTRACT(day FROM ds.acq_time_start) AS day
   FROM ((public.t_eus_usage_type eut
     JOIN public.t_requested_run rr ON ((eut.eus_usage_type_id = rr.eus_usage_type_id)))
     RIGHT JOIN (public.t_dataset ds
     JOIN public.t_instrument_name ON ((ds.instrument_id = t_instrument_name.instrument_id))) ON ((rr.dataset_id = ds.dataset_id)))
  WHERE (NOT (ds.acq_time_start IS NULL));


ALTER TABLE public.v_ops_logs_list_report OWNER TO d3l243;

--
-- Name: TABLE v_ops_logs_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_ops_logs_list_report TO readaccess;

