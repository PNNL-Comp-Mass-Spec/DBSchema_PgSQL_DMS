--
-- Name: v_dataset_info; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_info AS
 SELECT di.dataset_id,
    ds.dataset,
    ((di.scan_count_ms + di.scan_count_msn) + COALESCE(di.scan_count_dia, 0)) AS scan_count,
    di.scan_count_ms,
    di.scan_count_msn,
    di.scan_count_dia,
    di.elution_time_max,
    ds.acq_length_minutes,
    ds.acq_time_start,
    ds.file_size_bytes,
    dsfiles.file_path,
    dsfiles.file_hash,
    di.tic_max_ms,
    di.tic_max_msn,
    di.bpi_max_ms,
    di.bpi_max_msn,
    di.tic_median_ms,
    di.tic_median_msn,
    di.bpi_median_ms,
    di.bpi_median_msn,
    di.scan_types,
    di.last_affected,
    di.profile_scan_count_ms,
    di.profile_scan_count_msn,
    di.centroid_scan_count_ms,
    di.centroid_scan_count_msn
   FROM (((public.t_dataset_info di
     JOIN public.t_dataset ds ON ((di.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_requested_run rr ON ((di.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_dataset_files dsfiles ON ((di.dataset_id = dsfiles.dataset_id)));


ALTER VIEW public.v_dataset_info OWNER TO d3l243;

--
-- Name: TABLE v_dataset_info; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_info TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_info TO writeaccess;

