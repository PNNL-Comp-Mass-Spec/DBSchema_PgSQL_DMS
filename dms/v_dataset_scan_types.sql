--
-- Name: v_dataset_scan_types; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_scan_types AS
 SELECT dst.entry_id,
    dst.dataset_id,
    ds.dataset,
    dst.scan_type,
    dst.scan_count,
    dst.scan_filter,
    ds.scan_count AS scan_count_total,
    ds.file_size_bytes,
    ds.acq_length_minutes,
    ds.acq_time_start,
    ds.created
   FROM (public.t_dataset_scan_types dst
     JOIN public.t_dataset ds ON ((dst.dataset_id = ds.dataset_id)));


ALTER TABLE public.v_dataset_scan_types OWNER TO d3l243;

--
-- Name: TABLE v_dataset_scan_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_scan_types TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_scan_types TO writeaccess;

