--
-- Name: v_eus_export_dataset_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_export_dataset_metadata AS
 SELECT d.dataset_id,
    d.dataset,
    inst.instrument,
    eus_inst.eus_instrument_id,
    dtn.dataset_type,
    COALESCE(d.acq_time_start, d.created) AS dataset_acq_time_start,
    u_ds_operator.name AS instrument_operator,
    drn.dataset_rating,
    e.experiment,
    o.organism,
    e.reason AS experiment_reason,
    e.comment AS experiment_comment,
    u_ex_researcher.name AS experiment_researcher,
    spr.prep_request_id,
    spr.assigned_personnel AS prep_request_staff,
    sprstate.state_name AS prep_request_state,
    c.campaign,
    COALESCE(u_projmgr.name, c.project_mgr_username) AS project_manager,
    COALESCE(u_pi.name, c.pi_username) AS project_pi,
    COALESCE(u_techlead.name, c.technical_lead) AS project_technical_lead,
    d.operator_username AS instrument_operator_username,
    e.researcher_username AS experiment_researcher_username,
    c.project_mgr_username AS project_manager_username,
    c.pi_username AS project_pi_username,
    c.technical_lead AS project_technical_lead_username,
    eut.eus_usage_type AS eus_usage,
    rr.eus_proposal_id AS eus_proposal,
    (((apath.archive_path)::text || '/'::text) || (d.folder_name)::text) AS dataset_path_aurora
   FROM (((((((((((public.t_campaign c
     JOIN (((((((public.t_dataset d
     JOIN public.t_instrument_name inst ON ((d.instrument_id = inst.instrument_id)))
     JOIN public.t_dataset_type_name dtn ON ((d.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_users u_ds_operator ON ((d.operator_username OPERATOR(public.=) u_ds_operator.username)))
     JOIN public.t_dataset_rating_name drn ON ((d.dataset_rating_id = drn.dataset_rating_id)))
     JOIN public.t_experiments e ON ((d.exp_id = e.exp_id)))
     JOIN public.t_users u_ex_researcher ON ((e.researcher_username OPERATOR(public.=) u_ex_researcher.username)))
     JOIN public.t_organisms o ON ((e.organism_id = o.organism_id))) ON ((c.campaign_id = e.campaign_id)))
     LEFT JOIN public.t_users u_techlead ON ((c.technical_lead OPERATOR(public.=) u_techlead.username)))
     LEFT JOIN public.t_users u_pi ON ((c.pi_username OPERATOR(public.=) u_pi.username)))
     LEFT JOIN public.t_users u_projmgr ON ((c.project_mgr_username OPERATOR(public.=) u_projmgr.username)))
     LEFT JOIN public.t_sample_prep_request spr ON (((e.sample_prep_request_id = spr.prep_request_id) AND (spr.prep_request_id <> 0))))
     LEFT JOIN public.t_sample_prep_request_state_name sprstate ON ((spr.state_id = sprstate.state_id)))
     LEFT JOIN public.t_requested_run rr ON ((rr.dataset_id = d.dataset_id)))
     LEFT JOIN public.t_eus_usage_type eut ON ((eut.eus_usage_type_id = rr.eus_usage_type_id)))
     LEFT JOIN public.v_eus_instrument_id_lookup eus_inst ON ((eus_inst.instrument_name OPERATOR(public.=) inst.instrument)))
     LEFT JOIN public.t_dataset_archive da ON ((da.dataset_id = d.dataset_id)))
     LEFT JOIN public.t_archive_path apath ON ((apath.archive_path_id = da.storage_path_id)))
  WHERE ((d.dataset_state_id = 3) AND (d.dataset_rating_id <> ALL (ARRAY['-1'::integer, '-2'::integer, '-5'::integer])));


ALTER VIEW public.v_eus_export_dataset_metadata OWNER TO d3l243;

--
-- Name: TABLE v_eus_export_dataset_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_export_dataset_metadata TO readaccess;
GRANT SELECT ON TABLE public.v_eus_export_dataset_metadata TO writeaccess;

