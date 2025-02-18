--
-- Name: v_requested_run_active_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_active_export AS
 SELECT rr.request_id AS request,
    rr.request_name AS name,
    rr.priority,
    rr.instrument_group AS instrument,
    dtn.dataset_type AS type,
    e.experiment,
    u.name AS requester,
    rr.created,
    rr.comment,
    rr.note,
    rr.work_package,
    rr.wellplate,
    rr.well,
    rr.request_internal_standard AS internal_standard,
    rr.instrument_setting AS instrument_settings,
    rr.special_instructions,
    lc.cart_name AS cart,
    rr.request_run_start AS run_start,
    rr.request_run_finish AS run_finish,
    eut.eus_usage_type AS usage_type,
    rrcu.user_list AS eus_users,
    rr.eus_proposal_id AS proposal_id,
    rr.mrm_attachment AS mrm_file_id,
    rr.block,
    rr.run_order,
    rr.batch_id AS batch,
    rr.vialing_conc,
    rr.vialing_vol
   FROM ((((((public.t_dataset_type_name dtn
     JOIN public.t_requested_run rr ON ((dtn.dataset_type_id = rr.request_type_id)))
     JOIN public.t_users u ON ((rr.requester_username OPERATOR(public.=) u.username)))
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
     JOIN public.t_lc_cart lc ON ((rr.cart_id = lc.cart_id)))
     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
     LEFT JOIN public.t_active_requested_run_cached_eus_users rrcu ON ((rr.request_id = rrcu.request_id)))
  WHERE (rr.state_name OPERATOR(public.=) ANY (ARRAY['Active'::public.citext, 'Holding'::public.citext]));


ALTER VIEW public.v_requested_run_active_export OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_active_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_active_export TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_active_export TO writeaccess;

