--
-- Name: v_sample_prep_request_planning_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_planning_report AS
 SELECT spr.prep_request_id AS id,
    u.name AS requester,
    spr.request_name,
    spr.created,
    spr.estimated_prep_time_days AS est_prep_time,
    spr.state_comment,
    spr.priority,
    sn.state_name AS state,
    spr.number_of_samples AS num_samples,
    spr.estimated_ms_runs AS ms_runs_tbg,
    qt.days_in_queue,
        CASE
            WHEN (spr.state_id = ANY (ARRAY[0, 4, 5])) THEN NULL::numeric
            ELSE qt.days_in_state
        END AS days_in_state,
    spr.requested_personnel AS req_personnel,
    spr.assigned_personnel AS assigned,
    spr.prep_method,
    spr.instrument_group AS instrument,
    spr.campaign,
    spr.work_package AS wp,
    COALESCE(cc.activation_state_name, ''::public.citext) AS wp_state,
        CASE
            WHEN (spr.state_id = ANY (ARRAY[4, 5])) THEN 0
            WHEN (qt.days_in_queue <= (30)::numeric) THEN 30
            WHEN (qt.days_in_queue <= (60)::numeric) THEN 60
            WHEN (qt.days_in_queue <= (90)::numeric) THEN 90
            ELSE 120
        END AS "#DaysInQueue",
        CASE
            WHEN ((spr.state_id <> 5) AND (cc.activation_state >= 3)) THEN 10
            ELSE (cc.activation_state)::integer
        END AS "#WPActivationState",
    spr.assigned_personnel_sort_key AS "#Assigned_SortKey"
   FROM ((((public.t_sample_prep_request spr
     JOIN public.t_sample_prep_request_state_name sn ON ((spr.state_id = sn.state_id)))
     LEFT JOIN public.t_users u ON ((spr.requester_prn OPERATOR(public.=) u.username)))
     LEFT JOIN public.v_sample_prep_request_queue_times qt ON ((spr.prep_request_id = qt.request_id)))
     LEFT JOIN public.v_charge_code_status cc ON ((spr.work_package OPERATOR(public.=) cc.charge_code)))
  WHERE ((spr.state_id > 0) AND (spr.state_id < 5) AND (spr.request_type OPERATOR(public.=) 'Default'::public.citext))
  GROUP BY spr.prep_request_id, u.name, spr.request_name, spr.created, spr.estimated_prep_time_days, spr.state_comment, spr.priority, sn.state_name, spr.number_of_samples, spr.estimated_ms_runs, qt.days_in_queue, qt.days_in_state, spr.requested_personnel, spr.assigned_personnel, spr.prep_method, spr.instrument_group, spr.campaign, spr.work_package, cc.activation_state_name, spr.state_id, cc.activation_state, spr.assigned_personnel_sort_key;


ALTER TABLE public.v_sample_prep_request_planning_report OWNER TO d3l243;

--
-- Name: VIEW v_sample_prep_request_planning_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_sample_prep_request_planning_report IS 'If the request is not closed, but the charge code is inactive, return 10 for #WPActivationState';

--
-- Name: TABLE v_sample_prep_request_planning_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_planning_report TO readaccess;

