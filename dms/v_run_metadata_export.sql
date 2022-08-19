--
-- Name: v_run_metadata_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_run_metadata_export AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    inst.instrument,
    dtn.dataset_type AS type,
    ds.separation_type,
    lc.lc_column,
    dsn.dataset_state AS state,
    drn.dataset_rating AS rating,
    ds.acq_time_start AS acquisition_start,
    ds.acq_time_end AS acquisition_end,
    ds.scan_count,
    ds.created,
    rr.request_id AS request,
    rr.request_name,
    rr.block,
    rr.run_order AS requested_run_order,
    e.experiment,
    predigest_int_std.name AS predigest_int_std,
    postdigest_int_std.name AS postdigest_int_std,
    c.campaign,
    ds.wellplate,
    ds.well,
    u.name_with_username AS operator,
    ds.comment,
    ((spath.vol_name_client)::text || (spath.storage_path)::text) AS storage
   FROM ((((((((((((public.t_dataset ds
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_users u ON ((ds.operator_prn OPERATOR(public.=) u.username)))
     JOIN public.t_dataset_rating_name drn ON ((ds.dataset_rating_id = drn.dataset_rating_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_internal_standards predigest_int_std ON ((e.internal_standard_id = predigest_int_std.internal_standard_id)))
     JOIN public.t_internal_standards postdigest_int_std ON ((e.post_digest_internal_std_id = postdigest_int_std.internal_standard_id)))
     JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)));


ALTER TABLE public.v_run_metadata_export OWNER TO d3l243;

--
-- Name: TABLE v_run_metadata_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_run_metadata_export TO readaccess;
GRANT SELECT ON TABLE public.v_run_metadata_export TO writeaccess;

