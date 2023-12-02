--
-- Name: v_dataset_info_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_info_detail_report AS
 SELECT ds.dataset,
    te.experiment,
    og.organism,
    instname.instrument,
    dtn.dataset_type,
    dsinfo.scan_types,
    ds.scan_count AS scan_count_total,
    dsinfo.scan_count_ms,
    dsinfo.scan_count_msn,
    dsinfo.scan_count_dia,
    (
        CASE
            WHEN (COALESCE(dsinfo.elution_time_max, (0)::real) < ('1000000'::numeric)::double precision) THEN dsinfo.elution_time_max
            ELSE ('1000000'::numeric)::real
        END)::numeric(9,2) AS elution_time_max,
    ds.acq_length_minutes AS acq_length,
    ((((ds.file_size_bytes)::numeric / 1024.0) / 1024.0))::numeric(9,1) AS file_size_mb,
    (dsinfo.tic_max_ms)::text AS tic_max_ms,
    (dsinfo.tic_max_msn)::text AS tic_max_msn,
    (dsinfo.bpi_max_ms)::text AS bpi_max_ms,
    (dsinfo.bpi_max_msn)::text AS bpi_max_msn,
    (dsinfo.tic_median_ms)::text AS tic_median_ms,
    (dsinfo.tic_median_msn)::text AS tic_median_msn,
    (dsinfo.bpi_median_ms)::text AS bpi_median_ms,
    (dsinfo.bpi_median_msn)::text AS bpi_median_msn,
    ds.separation_type,
    lccart.cart_name AS lc_cart,
    lc.lc_column,
    ds.wellplate,
    ds.well,
    u.name_with_username AS operator,
    ds.acq_time_start AS acquisition_start,
    ds.acq_time_end AS acquisition_end,
    rr.request_run_start AS run_start,
    rr.request_run_finish AS run_finish,
    dsn.dataset_state AS state,
    dsrating.dataset_rating AS rating,
    ds.comment,
    ds.created,
    ds.dataset_id AS id,
        CASE
            WHEN ((ds.dataset_state_id = ANY (ARRAY[3, 4])) AND (COALESCE(dsa.archive_state_id, 0) <> 4)) THEN (((spath.vol_name_client)::text || (spath.storage_path)::text) || (COALESCE(ds.folder_name, ds.dataset))::text)
            ELSE '(not available)'::text
        END AS dataset_folder_path,
        CASE
            WHEN (COALESCE(dsa.archive_state_id, 0) = ANY (ARRAY[3, 4, 10, 14, 15])) THEN (((dap.archive_path)::text || '\'::text) || (COALESCE(ds.folder_name, ds.dataset))::text)
            ELSE '(not available)'::text
        END AS archive_folder_path,
    (((spath.url_https)::text || (COALESCE(ds.folder_name, ds.dataset))::text) || '/'::text) AS data_folder_link,
    (((spath.url_https)::text || (COALESCE(ds.folder_name, ds.dataset))::text) || '/QC/index.html'::text) AS qc_link,
    dsinfo.last_affected AS dsinfo_updated
   FROM ((((((((((((((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_dataset_info dsinfo ON ((ds.dataset_id = dsinfo.dataset_id)))
     JOIN public.t_experiments te ON ((ds.exp_id = te.exp_id)))
     JOIN public.t_organisms og ON ((te.organism_id = og.organism_id)))
     JOIN public.t_users u ON ((ds.operator_username OPERATOR(public.=) u.username)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_storage_path spath ON ((spath.storage_path_id = ds.storage_path_id)))
     LEFT JOIN public.t_lc_cart lccart ON ((lccart.cart_id = rr.cart_id)))
     LEFT JOIN public.t_dataset_archive dsa ON ((dsa.dataset_id = ds.dataset_id)))
     LEFT JOIN public.v_dataset_archive_path dap ON ((ds.dataset_id = dap.dataset_id)));


ALTER VIEW public.v_dataset_info_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_info_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_info_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_info_detail_report TO writeaccess;

