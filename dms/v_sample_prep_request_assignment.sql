--
-- Name: v_sample_prep_request_assignment; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_assignment AS
 SELECT ''::text AS sel,
    spr.prep_request_id AS id,
    spr.created,
    spr.estimated_prep_time_days AS est_prep_time,
    sn.state_name AS state,
    spr.state_comment,
    spr.request_name AS name,
    qp.name_with_username AS requester,
    spr.priority,
    qt.days_in_queue,
    spr.requested_personnel AS requested,
    spr.assigned_personnel AS assigned,
    spr.organism,
    bto.tissue,
    spr.biohazard_level AS biohazard,
    spr.campaign,
    spr.number_of_samples AS samples,
    spr.sample_type,
    spr.prep_method,
    spr.comment,
    spr.reason,
    spr.eus_proposal_id AS eus_proposal,
    ept.proposal_type_name AS eus_proposal_type,
        CASE
            WHEN (spr.state_id = ANY (ARRAY[4, 5])) THEN 0
            WHEN (qt.days_in_queue <= (30)::numeric) THEN 30
            WHEN (qt.days_in_queue <= (60)::numeric) THEN 60
            WHEN (qt.days_in_queue <= (90)::numeric) THEN 90
            ELSE 120
        END AS days_in_queue_bin
   FROM ((((((public.t_sample_prep_request spr
     JOIN public.t_sample_prep_request_state_name sn ON ((spr.state_id = sn.state_id)))
     LEFT JOIN public.t_users qp ON ((spr.requester_prn OPERATOR(public.=) qp.username)))
     LEFT JOIN public.v_sample_prep_request_queue_times qt ON ((spr.prep_request_id = qt.request_id)))
     LEFT JOIN public.t_eus_proposals eup ON ((spr.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)))
     LEFT JOIN ont.v_bto_id_to_name bto ON ((spr.tissue_id OPERATOR(public.=) bto.identifier)))
  WHERE ((spr.state_id > 0) AND (spr.request_type OPERATOR(public.=) 'Default'::public.citext));


ALTER TABLE public.v_sample_prep_request_assignment OWNER TO d3l243;

--
-- Name: TABLE v_sample_prep_request_assignment; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_assignment TO readaccess;
GRANT SELECT ON TABLE public.v_sample_prep_request_assignment TO writeaccess;

