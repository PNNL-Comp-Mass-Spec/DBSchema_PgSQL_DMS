--
-- Name: v_requested_run_fraction_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_fraction_entry AS
 SELECT rr.request_id AS source_request_id,
    rr.request_name AS source_request_name,
    e.experiment,
    rr.instrument_group,
    dtn.dataset_type AS run_type,
    rr.separation_group AS source_separation_group,
    ''::text AS separation_group,
    rr.requester_prn AS requester,
    rr.instrument_setting AS instrument_settings,
    ml.tag AS staging_location,
    rr.wellplate,
    rr.well,
    rr.vialing_conc AS vialing_concentration,
    rr.vialing_vol AS vialing_volume,
    rr.comment,
    rr.work_package,
    eut.eus_usage_type,
    rr.eus_proposal_id,
    public.get_requested_run_eus_users_list(rr.request_id, 'I'::text) AS eus_user,
    COALESCE(t_attachments.attachment_name, ''::public.citext) AS mrm_attachment
   FROM (((((public.t_requested_run rr
     JOIN public.t_dataset_type_name dtn ON ((dtn.dataset_type_id = rr.request_type_id)))
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
     LEFT JOIN public.t_attachments ON ((rr.mrm_attachment = t_attachments.attachment_id)))
     LEFT JOIN public.t_material_locations ml ON ((rr.location_id = ml.location_id)));


ALTER TABLE public.v_requested_run_fraction_entry OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_fraction_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_fraction_entry TO readaccess;

