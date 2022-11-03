--
-- Name: v_sample_prep_request_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_detail_report AS
 SELECT spr.prep_request_id AS id,
    spr.request_name,
    qp.name_with_username AS requester,
    spr.campaign,
    spr.reason,
    spr.material_container_list AS material_containers,
    spr.organism,
    bto.tissue AS plant_or_animal_tissue,
    spr.biohazard_level,
    spr.number_of_samples,
    spr.block_and_randomize_samples,
    spr.sample_name_list,
    spr.sample_type,
    spr.prep_method,
    spr.special_instructions,
    spr.comment,
    spr.estimated_ms_runs AS ms_runs_to_be_generated,
    spr.instrument_group,
    spr.dataset_type,
    spr.separation_type AS separation_group,
    spr.instrument_analysis_specifications,
    spr.block_and_randomize_runs,
    spr.sample_naming_convention AS sample_group_naming_prefix,
    spr.work_package,
    COALESCE(cc.activation_state_name, 'Invalid'::public.citext) AS work_package_state,
    spr.eus_usage_type,
    spr.eus_proposal_id AS eus_proposal,
    ept.proposal_type_name AS eus_proposal_type,
    (eup.proposal_end_date)::date AS eus_proposal_end_date,
    psn.state_name AS eus_proposal_state,
    public.get_sample_prep_request_eus_users_list(spr.prep_request_id, 'V'::bpchar) AS eus_user,
    spr.requested_personnel,
    spr.assigned_personnel,
    spr.estimated_prep_time_days,
    spr.priority,
    spr.reason_for_high_priority,
    sn.state_name AS state,
    spr.state_comment,
    spr.created,
    qt.complete_or_closed,
    qt.days_in_queue,
        CASE
            WHEN (spr.state_id = ANY (ARRAY[0, 4, 5])) THEN NULL::numeric
            ELSE qt.days_in_state
        END AS days_in_state,
    public.experiments_from_request(spr.prep_request_id) AS experiments,
    nu.updates,
    spr.biomaterial_item_count,
    spr.experiment_item_count,
    spr.experiment_group_item_count,
    spr.material_containers_item_count,
    spr.requested_run_item_count,
    spr.dataset_item_count,
    spr.hplc_runs_item_count,
    spr.total_item_count,
        CASE
            WHEN ((spr.state_id <> 5) AND (cc.activation_state >= 3)) THEN 10
            ELSE (cc.activation_state)::integer
        END AS wp_activation_state
   FROM (((((((((public.t_sample_prep_request spr
     JOIN public.t_sample_prep_request_state_name sn ON ((spr.state_id = sn.state_id)))
     LEFT JOIN public.t_users qp ON ((spr.requester_prn OPERATOR(public.=) qp.username)))
     LEFT JOIN ( SELECT t_sample_prep_request_updates.request_id,
            count(*) AS updates
           FROM public.t_sample_prep_request_updates
          GROUP BY t_sample_prep_request_updates.request_id) nu ON ((spr.prep_request_id = nu.request_id)))
     LEFT JOIN public.v_sample_prep_request_queue_times qt ON ((spr.prep_request_id = qt.request_id)))
     LEFT JOIN public.v_charge_code_status cc ON ((spr.work_package OPERATOR(public.=) cc.charge_code)))
     LEFT JOIN public.t_eus_proposals eup ON ((spr.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)))
     LEFT JOIN public.t_eus_proposal_state_name psn ON ((eup.state_id = psn.state_id)))
     LEFT JOIN ont.v_bto_id_to_name bto ON ((spr.tissue_id OPERATOR(public.=) bto.identifier)))
  WHERE (spr.request_type OPERATOR(public.=) 'Default'::public.citext);


ALTER TABLE public.v_sample_prep_request_detail_report OWNER TO d3l243;

--
-- Name: VIEW v_sample_prep_request_detail_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_sample_prep_request_detail_report IS 'If the request is not closed, but the charge code is inactive, return 10 for wp_activation_state';

--
-- Name: TABLE v_sample_prep_request_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_sample_prep_request_detail_report TO writeaccess;

