--
-- Name: v_dataset_scans_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_scans_detail_report AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    instname.instrument,
    dtn.dataset_type,
    dsinfo.scan_types,
    ds.scan_count AS scan_count_total,
    dsinfo.profile_scan_count_ms,
    dsinfo.profile_scan_count_msn,
    dsinfo.centroid_scan_count_ms,
    dsinfo.centroid_scan_count_msn,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'MS'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_ms,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'HMS'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_hms,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'Zoom-MS'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_zoom_ms,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'CID-MSn'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_cid_msn,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'CID-HMSn'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_cid_hmsn,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'HMSn'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_hmsn,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'HCD-HMSn'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_hcd_hmsn,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'ETD-MSn'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_etd_msn,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'ETD-HMSn'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_etd_hmsn,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'SA_ETD-MSn'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_sa_etd_msn,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'SA_ETD-HMSn'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_sa_etd_hmsn,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'Q1MS'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_q1ms,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'Q3MS'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_q3ms,
    sum(
        CASE
            WHEN (dst.scan_type OPERATOR(public.=) 'CID-SRM'::public.citext) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_cid_srm,
    sum(
        CASE
            WHEN (NOT (dst.scan_type OPERATOR(public.=) ANY (ARRAY['MS'::public.citext, 'HMS'::public.citext, 'Zoom-MS'::public.citext, 'CID-MSn'::public.citext, 'CID-HMSn'::public.citext, 'HMSn'::public.citext, 'HCD-HMSn'::public.citext, 'ETD-MSn'::public.citext, 'ETD-HMSn'::public.citext, 'SA_ETD-MSn'::public.citext, 'SA_ETD-HMSn'::public.citext, 'Q1MS'::public.citext, 'Q3MS'::public.citext, 'CID-SRM'::public.citext]))) THEN dst.scan_count
            ELSE 0
        END) AS scan_count_other,
        CASE
            WHEN (COALESCE(dsinfo.elution_time_max, (0)::real) < ('1000000'::numeric)::double precision) THEN dsinfo.elution_time_max
            ELSE ('1000000'::numeric)::real
        END AS elution_time_max,
    round((((ds.file_size_bytes)::numeric / 1024.0) / 1024.0), 1) AS file_size_mb
   FROM ((((public.t_dataset ds
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_info dsinfo ON ((ds.dataset_id = dsinfo.dataset_id)))
     JOIN public.t_dataset_scan_types dst ON ((ds.dataset_id = dst.dataset_id)))
  GROUP BY ds.dataset_id, ds.dataset, instname.instrument, dtn.dataset_type, ds.scan_count, dsinfo.elution_time_max, ds.file_size_bytes, dsinfo.scan_types, dsinfo.profile_scan_count_ms, dsinfo.profile_scan_count_msn, dsinfo.centroid_scan_count_ms, dsinfo.centroid_scan_count_msn;


ALTER TABLE public.v_dataset_scans_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_scans_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_scans_detail_report TO readaccess;

