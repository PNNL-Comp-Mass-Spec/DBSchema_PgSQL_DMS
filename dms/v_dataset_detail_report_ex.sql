--
-- Name: v_dataset_detail_report_ex; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_detail_report_ex AS
 SELECT ds.dataset,
    e.experiment,
    og.organism,
    bto.term_name AS experiment_tissue,
    instname.instrument,
    ds.separation_type,
    lccart.cart_name AS lc_cart,
    cartconfig.cart_config_name AS lc_cart_config,
    lccol.lc_column,
    ds.wellplate,
    ds.well,
    dst.dataset_type AS type,
    u.name_with_username AS operator,
    ds.comment,
    tdrn.dataset_rating AS rating,
    tdsn.dataset_state AS state,
    ds.dataset_id AS id,
    ds.created,
    rr.request_id AS request,
    rr.batch_id AS batch,
    dl.dataset_folder_path,
    dl.archive_folder_path,
    dl.myemsl_url,
    public.get_myemsl_transaction_id_urls(ds.dataset_id) AS myemsl_upload_ids,
    dfp.dataset_url AS data_folder_link,
    dl.qc_link,
    dl.qc_2d,
        CASE
            WHEN (char_length((COALESCE(dl.masic_directory_name, ''::public.citext))::text) = 0) THEN ''::text
            ELSE ((dfp.dataset_url)::text || (dl.masic_directory_name)::text)
        END AS masic_qc_link,
    dl.qc_metric_stats,
    COALESCE((cds.job_count)::bigint, (0)::bigint) AS jobs,
    COALESCE((cds.psm_job_count)::bigint, (0)::bigint) AS psm_jobs,
    public.get_dataset_pm_task_count(ds.dataset_id) AS peak_matching_results,
    public.get_dataset_factor_count(ds.dataset_id) AS factors,
    public.get_dataset_predefine_job_count(ds.dataset_id) AS predefines_triggered,
    ds.acq_time_start AS acquisition_start,
    ds.acq_time_end AS acquisition_end,
    rr.request_run_start AS run_start,
    rr.request_run_finish AS run_finish,
    ds.scan_count,
    public.get_dataset_scan_type_list(ds.dataset_id) AS scan_types,
    ds.acq_length_minutes AS acq_length,
    (round((((ds.file_size_bytes)::numeric / 1024.0) / 1024.0)))::integer AS file_size_mb,
    ds.file_info_last_modified AS file_info_updated,
    df.file_path AS dataset_file,
    df.file_hash AS sha1_hash,
    ds.folder_name,
    ds.capture_subfolder,
    tdasn.archive_state,
    da.archive_state_last_affected,
    ausn.archive_update_state,
    da.archive_update_state_last_affected,
    rr.work_package,
        CASE
            WHEN (rr.work_package OPERATOR(public.=) ANY (ARRAY['none'::public.citext, ''::public.citext])) THEN ''::public.citext
            ELSE COALESCE(cc.activation_state_name, 'Invalid'::public.citext)
        END AS work_package_state,
    eut.eus_usage_type,
    rr.eus_proposal_id AS eus_proposal,
    ept.proposal_type_name AS eus_proposal_type,
    public.get_requested_run_eus_users_list(rr.request_id, 'V'::text) AS eus_user,
    tispre.name AS predigest_int_std,
    tispost.name AS postdigest_int_std,
    t_myemsl_state.myemsl_state_name AS myemsl_state
   FROM ((((((((((((((ont.t_cv_bto_cached_names bto
     RIGHT JOIN ((((((((((public.t_dataset ds
     JOIN public.t_dataset_state_name tdsn ON ((ds.dataset_state_id = tdsn.dataset_state_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_type_name dst ON ((ds.dataset_type_id = dst.dataset_type_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_users u ON ((ds.operator_username OPERATOR(public.=) u.username)))
     JOIN public.t_dataset_rating_name tdrn ON ((ds.dataset_rating_id = tdrn.dataset_rating_id)))
     JOIN public.t_lc_column lccol ON ((ds.lc_column_id = lccol.lc_column_id)))
     JOIN public.t_internal_standards tispre ON ((e.internal_standard_id = tispre.internal_standard_id)))
     JOIN public.t_internal_standards tispost ON ((e.post_digest_internal_std_id = tispost.internal_standard_id)))
     JOIN public.t_organisms og ON ((e.organism_id = og.organism_id))) ON ((bto.identifier OPERATOR(public.=) e.tissue_id)))
     LEFT JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     LEFT JOIN public.t_cached_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     LEFT JOIN public.t_cached_dataset_links dl ON ((ds.dataset_id = dl.dataset_id)))
     LEFT JOIN public.v_dataset_archive_path dap ON ((ds.dataset_id = dap.dataset_id)))
     LEFT JOIN (((public.t_lc_cart lccart
     JOIN public.t_requested_run rr ON ((lccart.cart_id = rr.cart_id)))
     LEFT JOIN public.t_eus_proposals eup ON ((rr.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type))) ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_cached_dataset_stats cds ON ((cds.dataset_id = ds.dataset_id)))
     LEFT JOIN (public.t_dataset_archive da
     JOIN public.t_myemsl_state ON ((da.myemsl_state = t_myemsl_state.myemsl_state))) ON ((da.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
     LEFT JOIN public.v_charge_code_status cc ON ((rr.work_package OPERATOR(public.=) cc.charge_code)))
     LEFT JOIN public.t_dataset_archive_state_name tdasn ON ((da.archive_state_id = tdasn.archive_state_id)))
     LEFT JOIN public.t_dataset_archive_update_state_name ausn ON ((da.archive_update_state_id = ausn.archive_update_state_id)))
     LEFT JOIN public.t_lc_cart_configuration cartconfig ON ((ds.cart_config_id = cartconfig.cart_config_id)))
     LEFT JOIN public.t_dataset_files df ON (((df.dataset_id = ds.dataset_id) AND (df.file_size_rank = 1))));


ALTER VIEW public.v_dataset_detail_report_ex OWNER TO d3l243;

--
-- Name: VIEW v_dataset_detail_report_ex; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_dataset_detail_report_ex IS 'Note: this view is intended to be used for retrieving information for a single dataset. Performance will be poor if used to query multiple datasets because it references several scalar-valued functions. For changes, see https://github.com/PNNL-Comp-Mass-Spec/DBSchema_DMS/commit/e843c6bb52';

--
-- Name: TABLE v_dataset_detail_report_ex; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_detail_report_ex TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_detail_report_ex TO writeaccess;

