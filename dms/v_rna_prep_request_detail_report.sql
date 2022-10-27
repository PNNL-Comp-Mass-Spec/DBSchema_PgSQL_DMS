--
-- Name: v_rna_prep_request_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_rna_prep_request_detail_report AS
 SELECT spr.prep_request_id AS id,
    spr.request_name,
    qp.name_with_username AS requester,
    spr.campaign,
    spr.reason,
    spr.organism,
    spr.biohazard_level,
    spr.number_of_samples,
    spr.sample_name_list,
    spr.sample_type,
    spr.prep_method,
    spr.instrument_name,
    spr.dataset_type,
    spr.instrument_analysis_specifications,
    spr.sample_naming_convention AS sample_group_naming_prefix,
    spr.work_package,
    COALESCE(cc.activation_state_name, 'Invalid'::public.citext) AS work_package_state,
    spr.eus_usage_type,
    spr.eus_proposal_id AS eus_proposal,
    public.get_sample_prep_request_eus_users_list(spr.prep_request_id, 'V'::bpchar) AS eus_user,
    spr.estimated_completion,
    sn.state_name AS state,
    spr.created,
    public.experiments_from_request(spr.prep_request_id) AS experiments,
    nu.updates,
        CASE
            WHEN ((spr.state_id <> 5) AND (cc.activation_state >= 3)) THEN 10
            ELSE (cc.activation_state)::integer
        END AS "#wp_activation_state"
   FROM ((((public.t_sample_prep_request spr
     JOIN public.t_sample_prep_request_state_name sn ON ((spr.state_id = sn.state_id)))
     LEFT JOIN public.t_users qp ON ((spr.requester_prn OPERATOR(public.=) qp.username)))
     LEFT JOIN ( SELECT t_sample_prep_request_updates.request_id,
            count(*) AS updates
           FROM public.t_sample_prep_request_updates
          GROUP BY t_sample_prep_request_updates.request_id) nu ON ((spr.prep_request_id = nu.request_id)))
     LEFT JOIN public.v_charge_code_status cc ON ((spr.work_package OPERATOR(public.=) cc.charge_code)))
  WHERE (spr.request_type OPERATOR(public.=) 'RNA'::public.citext);


ALTER TABLE public.v_rna_prep_request_detail_report OWNER TO d3l243;

--
-- Name: VIEW v_rna_prep_request_detail_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_rna_prep_request_detail_report IS 'If the request is not closed, but the charge code is inactive, return 10 for #wp_activation_state';

--
-- Name: TABLE v_rna_prep_request_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_rna_prep_request_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_rna_prep_request_detail_report TO writeaccess;

