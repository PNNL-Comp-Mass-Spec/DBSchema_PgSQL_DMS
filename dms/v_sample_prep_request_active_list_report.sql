--
-- Name: v_sample_prep_request_active_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_active_list_report AS
 SELECT spr.prep_request_id AS id,
    spr.request_name,
    spr.created,
    spr.estimated_prep_time_days AS est_prep_time,
    spr.priority,
    ta.attachments AS files,
    sn.state_name AS state,
    spr.state_comment,
    spr.reason,
    spr.number_of_samples AS num_samples,
    spr.estimated_ms_runs AS ms_runs_tbg,
    qt.days_in_queue,
    spr.prep_method,
    spr.requested_personnel,
    spr.assigned_personnel,
    qp.name_with_username AS requester,
    spr.organism,
    bto.tissue,
    spr.biohazard_level,
    spr.campaign,
    spr.comment,
    spr.work_package,
    COALESCE(cc.activation_state_name, ''::public.citext) AS wp_state,
    spr.eus_proposal_id AS eus_proposal,
    ept.proposal_type_name AS eus_proposal_type,
    spr.instrument_group AS inst_group,
    spr.instrument_analysis_specifications AS inst_analysis,
        CASE
            WHEN (spr.state_id = ANY (ARRAY[4, 5])) THEN 0
            WHEN (qt.days_in_queue <= (30)::numeric) THEN 30
            WHEN (qt.days_in_queue <= (60)::numeric) THEN 60
            WHEN (qt.days_in_queue <= (90)::numeric) THEN 90
            ELSE 120
        END AS days_in_queue_bin,
        CASE
            WHEN ((spr.state_id <> 5) AND (cc.activation_state >= 3)) THEN 10
            ELSE (cc.activation_state)::integer
        END AS wp_activation_state
   FROM ((((((((public.t_sample_prep_request spr
     JOIN public.t_sample_prep_request_state_name sn ON ((spr.state_id = sn.state_id)))
     LEFT JOIN public.t_users qp ON ((spr.requester_username OPERATOR(public.=) qp.username)))
     LEFT JOIN public.v_sample_prep_request_queue_times qt ON ((spr.prep_request_id = qt.request_id)))
     LEFT JOIN ( SELECT t_file_attachment.entity_id_value,
            count(t_file_attachment.attachment_id) AS attachments
           FROM public.t_file_attachment
          WHERE ((t_file_attachment.entity_type OPERATOR(public.=) 'sample_prep_request'::public.citext) AND (t_file_attachment.active > 0))
          GROUP BY t_file_attachment.entity_id_value) ta ON ((spr.prep_request_id = ta.entity_id_value)))
     LEFT JOIN public.v_charge_code_status cc ON ((spr.work_package OPERATOR(public.=) cc.charge_code)))
     LEFT JOIN public.t_eus_proposals eup ON ((spr.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)))
     LEFT JOIN ont.v_bto_id_to_name bto ON ((spr.tissue_id OPERATOR(public.=) bto.identifier)))
  WHERE ((NOT (spr.state_id = ANY (ARRAY[0, 4, 5]))) AND (spr.request_type OPERATOR(public.=) 'Default'::public.citext));


ALTER TABLE public.v_sample_prep_request_active_list_report OWNER TO d3l243;

--
-- Name: VIEW v_sample_prep_request_active_list_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_sample_prep_request_active_list_report IS 'If the request is not closed, but the charge code is inactive, return 10 for wp_activation_state';

--
-- Name: TABLE v_sample_prep_request_active_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_active_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_sample_prep_request_active_list_report TO writeaccess;

