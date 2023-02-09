--
-- Name: v_rna_prep_request_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_rna_prep_request_entry AS
 SELECT spr.request_name,
    spr.requester_username,
    spr.reason,
    spr.organism,
    spr.biohazard_level,
    spr.campaign,
    spr.number_of_samples,
    spr.sample_name_list,
    spr.sample_type,
    spr.prep_method,
    spr.sample_naming_convention,
    spr.estimated_completion,
    spr.work_package,
    spr.instrument_name,
    spr.dataset_type,
    spr.instrument_analysis_specifications,
    sn.state_name AS state,
    spr.prep_request_id AS id,
    spr.eus_usage_type,
    spr.eus_proposal_id,
    spr.eus_user_id
   FROM (public.t_sample_prep_request spr
     JOIN public.t_sample_prep_request_state_name sn ON ((spr.state_id = sn.state_id)));


ALTER TABLE public.v_rna_prep_request_entry OWNER TO d3l243;

--
-- Name: TABLE v_rna_prep_request_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_rna_prep_request_entry TO readaccess;
GRANT SELECT ON TABLE public.v_rna_prep_request_entry TO writeaccess;

