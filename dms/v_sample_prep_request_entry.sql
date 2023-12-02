--
-- Name: v_sample_prep_request_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_entry AS
 SELECT spr.prep_request_id AS id,
    spr.request_name,
    spr.requester_username,
    ((spr.reason)::text || '__NoCopy__'::text) AS reason,
    spr.organism,
    bto.tissue,
    spr.biohazard_level,
    spr.campaign,
    ((spr.number_of_samples)::text || '__NoCopy__'::text) AS number_of_samples,
    spr.sample_name_list,
    spr.sample_type,
    spr.prep_method,
    spr.sample_naming_convention,
    spr.requested_personnel,
    spr.assigned_personnel,
    spr.estimated_prep_time_days,
    ((spr.estimated_ms_runs)::text || '__NoCopy__'::text) AS estimated_ms_runs,
    spr.work_package,
    spr.instrument_group,
    spr.dataset_type,
    spr.instrument_analysis_specifications,
    ((spr.comment)::text || '__NoCopy__'::text) AS comment,
    spr.priority,
    sn.state_name AS state,
    spr.state_comment,
    spr.eus_usage_type,
    spr.eus_proposal_id,
    spr.eus_user_id,
    spr.facility,
    spr.separation_group,
    spr.block_and_randomize_samples,
    spr.block_and_randomize_runs,
    ((spr.reason_for_high_priority)::text || '__NoCopy__'::text) AS reason_for_high_priority,
    ((spr.material_container_list)::text || '__NoCopy__'::text) AS material_container_list
   FROM ((public.t_sample_prep_request spr
     JOIN public.t_sample_prep_request_state_name sn ON ((spr.state_id = sn.state_id)))
     LEFT JOIN ont.v_bto_id_to_name bto ON ((spr.tissue_id OPERATOR(public.=) bto.identifier)));


ALTER VIEW public.v_sample_prep_request_entry OWNER TO d3l243;

--
-- Name: TABLE v_sample_prep_request_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_entry TO readaccess;
GRANT SELECT ON TABLE public.v_sample_prep_request_entry TO writeaccess;

