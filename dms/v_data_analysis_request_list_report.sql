--
-- Name: v_data_analysis_request_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_analysis_request_list_report AS
 SELECT r.request_id AS id,
    r.request_name,
    r.analysis_type,
    r.created,
    r.estimated_analysis_time_days AS est_analysis_time,
    r.priority,
    ta.attachments AS files,
    sn.state_name AS state,
    r.state_comment,
    u.name_with_username AS requester,
    r.description,
    qt.days_in_queue,
    r.requested_personnel,
    r.assigned_personnel,
    r.representative_batch_id AS batch,
    r.representative_data_pkg_id AS data_package,
    r.exp_group_id AS exp_group,
    r.campaign,
    r.organism,
    r.dataset_count,
    r.work_package,
    COALESCE(cc.activation_state_name, 'Invalid'::public.citext) AS wp_state,
    r.eus_proposal_id AS eus_proposal,
    ept.proposal_type_name AS eus_proposal_type,
        CASE
            WHEN (r.state = 4) THEN 0
            WHEN (qt.days_in_queue <= (30)::numeric) THEN 30
            WHEN (qt.days_in_queue <= (60)::numeric) THEN 60
            WHEN (qt.days_in_queue <= (90)::numeric) THEN 90
            ELSE 120
        END AS days_in_queue_bin,
        CASE
            WHEN ((r.state <> 4) AND (cc.activation_state >= 3)) THEN 10
            ELSE (cc.activation_state)::integer
        END AS wp_activation_state
   FROM (((((((public.t_data_analysis_request r
     JOIN public.t_data_analysis_request_state_name sn ON ((r.state = sn.state_id)))
     LEFT JOIN public.t_users u ON ((r.requester_username OPERATOR(public.=) u.username)))
     LEFT JOIN public.v_data_analysis_request_queue_times qt ON ((r.request_id = qt.request_id)))
     LEFT JOIN ( SELECT t_file_attachment.entity_id_value,
            count(t_file_attachment.attachment_id) AS attachments
           FROM public.t_file_attachment
          WHERE ((t_file_attachment.entity_type OPERATOR(public.=) 'data_analysis_request'::public.citext) AND (t_file_attachment.active > 0))
          GROUP BY t_file_attachment.entity_id_value) ta ON ((r.request_id = ta.entity_id_value)))
     LEFT JOIN public.v_charge_code_status cc ON ((r.work_package OPERATOR(public.=) cc.charge_code)))
     LEFT JOIN public.t_eus_proposals eup ON ((r.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)))
  WHERE (r.state > 0);


ALTER VIEW public.v_data_analysis_request_list_report OWNER TO d3l243;

--
-- Name: VIEW v_data_analysis_request_list_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_data_analysis_request_list_report IS 'If the analysis request is not closed, but the charge code is inactive, return 10 for wp_activation_state';

--
-- Name: TABLE v_data_analysis_request_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_analysis_request_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_data_analysis_request_list_report TO writeaccess;

