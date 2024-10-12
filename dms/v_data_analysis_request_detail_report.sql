--
-- Name: v_data_analysis_request_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_analysis_request_detail_report AS
 SELECT r.request_id AS id,
    r.request_name,
    r.analysis_type,
    u.name_with_username AS requester,
    r.description,
    r.analysis_specifications,
    r.comment,
    public.get_data_analysis_request_batch_list(r.request_id) AS requested_run_batch_ids,
    public.get_data_analysis_request_data_package_list(r.request_id) AS data_package_ids,
    r.exp_group_id AS experiment_group,
    r.campaign,
    r.organism,
    r.dataset_count,
    r.work_package,
    COALESCE(cc.activation_state_name, 'Invalid'::public.citext) AS work_package_state,
    r.eus_proposal_id AS eus_proposal,
    ept.proposal_type_name AS eus_proposal_type,
    (eup.proposal_end_date)::date AS eus_proposal_end_date,
    psn.state_name AS eus_proposal_state,
    r.requested_personnel,
    r.assigned_personnel,
    r.priority,
    r.reason_for_high_priority,
    r.estimated_analysis_time_days,
    sn.state_name AS state,
    r.state_comment,
    r.created,
    qt.closed,
    qt.days_in_queue,
        CASE
            WHEN (r.state = ANY (ARRAY[0, 4])) THEN NULL::numeric
            ELSE qt.days_in_state
        END AS days_in_state,
    updateq.updates,
        CASE
            WHEN ((r.state <> 4) AND (cc.activation_state >= 3)) THEN 10
            ELSE (cc.activation_state)::integer
        END AS wp_activation_state
   FROM ((((((((public.t_data_analysis_request r
     JOIN public.t_data_analysis_request_state_name sn ON ((r.state = sn.state_id)))
     LEFT JOIN public.t_users u ON ((r.requester_username OPERATOR(public.=) u.username)))
     LEFT JOIN ( SELECT t_data_analysis_request_updates.request_id,
            count(t_data_analysis_request_updates.id) AS updates
           FROM public.t_data_analysis_request_updates
          GROUP BY t_data_analysis_request_updates.request_id) updateq ON ((r.request_id = updateq.request_id)))
     LEFT JOIN public.v_data_analysis_request_queue_times qt ON ((r.request_id = qt.request_id)))
     LEFT JOIN public.v_charge_code_status cc ON ((r.work_package OPERATOR(public.=) cc.charge_code)))
     LEFT JOIN public.t_eus_proposals eup ON ((r.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)))
     LEFT JOIN public.t_eus_proposal_state_name psn ON ((eup.state_id = psn.state_id)));


ALTER VIEW public.v_data_analysis_request_detail_report OWNER TO d3l243;

--
-- Name: VIEW v_data_analysis_request_detail_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_data_analysis_request_detail_report IS 'If the analysis request is not closed, but the charge code is inactive, return 10 for wp_activation_state';

--
-- Name: TABLE v_data_analysis_request_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_analysis_request_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_data_analysis_request_detail_report TO writeaccess;

