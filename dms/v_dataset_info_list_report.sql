--
-- Name: v_dataset_info_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_info_list_report AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    instname.instrument,
    dtn.dataset_type,
    dsinfo.scan_types,
    ds.scan_count AS scan_count_total,
    dsinfo.scan_count_ms,
    dsinfo.scan_count_msn,
    dsinfo.scan_count_dia,
        CASE
            WHEN (COALESCE(dsinfo.elution_time_max, (0)::real) < ('1000000'::numeric)::double precision) THEN dsinfo.elution_time_max
            ELSE ('1000000'::numeric)::real
        END AS elution_time_max,
    ds.acq_length_minutes AS acq_length,
    round((((ds.file_size_bytes)::numeric / 1024.0) / 1024.0), 1) AS file_size_mb,
    dsinfo.tic_max_ms,
    dsinfo.tic_max_msn,
    dsinfo.bpi_max_ms,
    dsinfo.bpi_max_msn,
    dsinfo.tic_median_ms,
    dsinfo.tic_median_msn,
    dsinfo.bpi_median_ms,
    dsinfo.bpi_median_msn,
    ds.separation_type,
    lc.lc_column,
    ds.acq_time_start AS acquisition_start,
    ds.acq_time_end AS acquisition_end,
    dsn.dataset_state AS state,
    dsrating.dataset_rating AS rating,
    ds.comment,
    ds.created,
    dsinfo.last_affected AS dsinfo_updated
   FROM (((((((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_dataset_info dsinfo ON ((ds.dataset_id = dsinfo.dataset_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)));


ALTER TABLE public.v_dataset_info_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_info_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_info_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_info_list_report TO writeaccess;

