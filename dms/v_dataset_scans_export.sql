--
-- Name: v_dataset_scans_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_scans_export AS
 SELECT ds.dataset_id,
    ds.dataset,
    instname.instrument,
    dtn.dataset_type,
    dst.scan_type,
    dst.scan_count,
    dst.scan_filter,
    ds.scan_count AS scan_count_total,
        CASE
            WHEN (COALESCE(dsinfo.elution_time_max, (0)::real) < ('1000000'::numeric)::double precision) THEN dsinfo.elution_time_max
            ELSE ('1000000'::numeric)::real
        END AS elution_time_max,
    round((((ds.file_size_bytes)::numeric / 1024.0) / 1024.0), 1) AS file_size_mb,
    dst.entry_id
   FROM ((((public.t_dataset ds
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_info dsinfo ON ((ds.dataset_id = dsinfo.dataset_id)))
     JOIN public.t_dataset_scan_types dst ON ((ds.dataset_id = dst.dataset_id)));


ALTER VIEW public.v_dataset_scans_export OWNER TO d3l243;

--
-- Name: TABLE v_dataset_scans_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_scans_export TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_scans_export TO writeaccess;

