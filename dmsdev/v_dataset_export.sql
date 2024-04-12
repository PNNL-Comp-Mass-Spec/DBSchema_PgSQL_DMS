--
-- Name: v_dataset_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_export AS
 SELECT ds.dataset,
    e.experiment,
    org.organism,
    inst.instrument,
    ds.separation_type,
    lc.lc_column,
    ds.wellplate,
    ds.well,
    dsintstd.name AS dataset_int_std,
    dtn.dataset_type AS type,
    u.name_with_username AS operator,
    ds.comment,
    dsrating.dataset_rating AS rating,
    rr.request_id AS request,
    ds.dataset_state_id AS state_id,
    dsn.dataset_state AS state,
    ds.created,
    ds.folder_name,
    dfpcache.dataset_folder_path,
    spath.storage_path,
    ((spath.vol_name_client)::text || (spath.storage_path)::text) AS storage,
    ds.dataset_id AS id,
    ds.acq_time_start AS acquisition_start,
    ds.acq_time_end AS acquisition_end,
    ds.scan_count,
    predigest.name AS predigest_int_std,
    postdigest.name AS postdigest_int_std,
    (((ds.file_size_bytes)::numeric / 1024.0) / 1024.0) AS file_size_mb,
    COALESCE((da.instrument_data_purged)::integer, 0) AS instrument_data_purged,
    dfpcache.archive_folder_path,
    COALESCE((da.myemsl_state)::integer, 0) AS myemsl_state
   FROM (((((((((((((((public.t_dataset ds
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_users u ON ((ds.operator_username OPERATOR(public.=) u.username)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_internal_standards dsintstd ON ((ds.internal_standard_id = dsintstd.internal_standard_id)))
     JOIN public.t_internal_standards predigest ON ((e.internal_standard_id = predigest.internal_standard_id)))
     JOIN public.t_internal_standards postdigest ON ((e.post_digest_internal_std_id = postdigest.internal_standard_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.t_cached_dataset_folder_paths dfpcache ON ((ds.dataset_id = dfpcache.dataset_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)))
  WHERE (e.experiment OPERATOR(public.<>) 'Tracking'::public.citext);


ALTER VIEW public.v_dataset_export OWNER TO d3l243;

--
-- Name: TABLE v_dataset_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_export TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_export TO writeaccess;

