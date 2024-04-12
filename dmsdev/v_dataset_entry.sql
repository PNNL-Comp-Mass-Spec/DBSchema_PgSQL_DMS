--
-- Name: v_dataset_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_entry AS
 SELECT e.experiment,
    inst.instrument AS instrument_name,
    dtn.dataset_type,
    ds.dataset,
    ds.folder_name,
    ds.operator_username,
    ds.wellplate,
    ds.well,
    ds.separation_type,
    ds.comment,
    dsrating.dataset_rating,
    0 AS request_id,
    lccol.lc_column,
    intstd.name AS internal_standard,
    eususage.eus_usage_type,
    rr.eus_proposal_id,
    public.get_requested_run_eus_users_list(rr.request_id, 'I'::text) AS eus_users,
    lccart.cart_name AS lc_cart_name,
    cartconfig.cart_config_name AS lc_cart_config,
    ds.capture_subfolder,
    ds.dataset_id
   FROM ((((((((((public.t_dataset ds
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_lc_column lccol ON ((ds.lc_column_id = lccol.lc_column_id)))
     JOIN public.t_internal_standards intstd ON ((ds.internal_standard_id = intstd.internal_standard_id)))
     LEFT JOIN public.t_requested_run rr ON ((rr.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_lc_cart lccart ON ((lccart.cart_id = rr.cart_id)))
     LEFT JOIN public.t_eus_usage_type eususage ON ((rr.eus_usage_type_id = eususage.eus_usage_type_id)))
     LEFT JOIN public.t_lc_cart_configuration cartconfig ON ((ds.cart_config_id = cartconfig.cart_config_id)));


ALTER VIEW public.v_dataset_entry OWNER TO d3l243;

--
-- Name: TABLE v_dataset_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_entry TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_entry TO writeaccess;

