--
-- Name: v_rna_prep_request_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_rna_prep_request_list_report AS
 SELECT spr.prep_request_id AS id,
    spr.request_name,
    spr.created,
    spr.estimated_completion AS est_complete,
    ta.attachments AS files,
    sn.state_name AS state,
    spr.reason,
    spr.number_of_samples AS num_samples,
    qt.days_in_queue,
    spr.prep_method,
    qp.name_with_username AS requester,
    spr.organism,
    spr.biohazard_level,
    spr.campaign,
    spr.work_package AS wp,
    COALESCE(cc.activation_state_name, ''::public.citext) AS wp_state,
    spr.instrument_name AS instrument,
    spr.instrument_analysis_specifications AS inst_analysis,
    spr.eus_proposal_id,
    spr.sample_naming_convention AS sample_prefix,
    sum(
        CASE
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (e.created)::timestamp with time zone)) / (86400)::numeric)) < (8)::numeric) THEN 1
            ELSE 0
        END) AS experiments_last_7days,
    sum(
        CASE
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (e.created)::timestamp with time zone)) / (86400)::numeric)) < (32)::numeric) THEN 1
            ELSE 0
        END) AS experiments_last_31days,
    sum(
        CASE
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (e.created)::timestamp with time zone)) / (86400)::numeric)) < (181)::numeric) THEN 1
            ELSE 0
        END) AS experiments_last_180days,
    sum(
        CASE
            WHEN (NOT (e.created IS NULL)) THEN 1
            ELSE 0
        END) AS experiments_total,
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
        END AS "#WPActivationState"
   FROM ((((((public.t_sample_prep_request spr
     JOIN public.t_sample_prep_request_state_name sn ON ((spr.state_id = sn.state_id)))
     LEFT JOIN public.t_users qp ON ((spr.requester_prn OPERATOR(public.=) qp.username)))
     LEFT JOIN public.v_sample_prep_request_queue_times qt ON ((spr.prep_request_id = qt.request_id)))
     LEFT JOIN ( SELECT t_file_attachment.entity_id,
            count(*) AS attachments
           FROM public.t_file_attachment
          WHERE ((t_file_attachment.entity_type OPERATOR(public.=) 'sample_prep_request'::public.citext) AND (t_file_attachment.active > 0))
          GROUP BY t_file_attachment.entity_id) ta ON ((spr.prep_request_id = (ta.entity_id)::integer)))
     LEFT JOIN public.t_experiments e ON ((spr.prep_request_id = e.sample_prep_request_id)))
     LEFT JOIN public.v_charge_code_status cc ON ((spr.work_package OPERATOR(public.=) cc.charge_code)))
  WHERE ((spr.state_id > 0) AND (spr.request_type OPERATOR(public.=) 'RNA'::public.citext))
  GROUP BY spr.prep_request_id, spr.request_name, spr.created, spr.estimated_completion, ta.attachments, spr.state_id, sn.state_name, spr.reason, spr.number_of_samples, qt.days_in_queue, spr.prep_method, qp.name_with_username, spr.organism, spr.biohazard_level, spr.campaign, spr.work_package, spr.instrument_name, spr.instrument_analysis_specifications, spr.eus_proposal_id, spr.sample_naming_convention, cc.activation_state, cc.activation_state_name;


ALTER TABLE public.v_rna_prep_request_list_report OWNER TO d3l243;

--
-- Name: VIEW v_rna_prep_request_list_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_rna_prep_request_list_report IS 'If the request is not closed, but the charge code is inactive, return 10 for #WPActivationState';

--
-- Name: TABLE v_rna_prep_request_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_rna_prep_request_list_report TO readaccess;

