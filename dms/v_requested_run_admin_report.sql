--
-- Name: v_requested_run_admin_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_admin_report AS
 SELECT rr.request_id AS request,
    rr.request_name AS name,
    c.campaign,
    e.experiment,
    ds.dataset,
    COALESCE(datasetinstrument.instrument, ''::public.citext) AS instrument,
    rr.instrument_group AS inst_group,
    ds.acq_time_start,
    dtn.dataset_type AS type,
    rr.separation_group,
    rr.origin,
    rr.state_name AS status,
    u.name AS requester,
    rr.work_package AS wpn,
    COALESCE(cca.activation_state_name, ''::public.citext) AS wp_state,
    qt.days_in_queue,
    qs.queue_state_name AS queue_state,
    COALESCE(assignedinstrument.instrument, ''::public.citext) AS queued_instrument,
    rr.queue_date,
    rr.priority,
    rr.batch_id AS batch,
    rr.block,
    rr.run_order,
    rr.comment,
    ds.comment AS dataset_comment,
    rr.request_name_code,
        CASE
            WHEN (NOT (rr.state_name OPERATOR(public.=) ANY (ARRAY['Active'::public.citext, 'Holding'::public.citext]))) THEN 0
            WHEN (qt.days_in_queue <= (30)::numeric) THEN 30
            WHEN (qt.days_in_queue <= (60)::numeric) THEN 60
            WHEN (qt.days_in_queue <= (90)::numeric) THEN 90
            ELSE 120
        END AS days_in_queue_bin,
        CASE
            WHEN ((rr.state_name OPERATOR(public.=) ANY (ARRAY['Active'::public.citext, 'Holding'::public.citext])) AND (rr.cached_wp_activation_state >= 3)) THEN 10
            ELSE (rr.cached_wp_activation_state)::integer
        END AS wp_activation_state
   FROM ((((((((((public.t_requested_run rr
     JOIN public.t_dataset_type_name dtn ON ((dtn.dataset_type_id = rr.request_type_id)))
     JOIN public.t_users u ON ((rr.requester_username OPERATOR(public.=) u.username)))
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_requested_run_queue_state qs ON ((rr.queue_state = qs.queue_state)))
     JOIN public.t_charge_code_activation_state cca ON ((rr.cached_wp_activation_state = cca.activation_state)))
     LEFT JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_instrument_name datasetinstrument ON ((ds.instrument_id = datasetinstrument.instrument_id)))
     LEFT JOIN public.t_instrument_name assignedinstrument ON ((rr.queue_instrument_id = assignedinstrument.instrument_id)))
     LEFT JOIN public.v_requested_run_queue_times qt ON ((rr.request_id = qt.requested_run_id)));


ALTER VIEW public.v_requested_run_admin_report OWNER TO d3l243;

--
-- Name: VIEW v_requested_run_admin_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_requested_run_admin_report IS 'If the requested run is Active or Holding, but the charge code is inactive, return 10 for wp_activation_state';

--
-- Name: TABLE v_requested_run_admin_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_admin_report TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_admin_report TO writeaccess;

