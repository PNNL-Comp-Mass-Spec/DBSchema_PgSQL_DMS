--
-- Name: v_dms_dataset_scans; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_dataset_scans AS
 SELECT ds.dataset_id,
    ds.dataset,
    instname.instrument,
    dtn.dataset_type,
    dst.scan_type,
    dst.scan_count,
    dst.scan_filter,
    ds.scan_count AS scan_count_total,
    dst.entry_id
   FROM (((public.t_dataset ds
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_scan_types dst ON ((ds.dataset_id = dst.dataset_id)));


ALTER VIEW cap.v_dms_dataset_scans OWNER TO d3l243;

--
-- Name: TABLE v_dms_dataset_scans; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dms_dataset_scans TO readaccess;
GRANT SELECT ON TABLE cap.v_dms_dataset_scans TO writeaccess;

