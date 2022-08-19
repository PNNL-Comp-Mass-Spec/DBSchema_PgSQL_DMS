--
-- Name: v_dms_get_dataset_definition; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_get_dataset_definition AS
 SELECT ds.dataset,
    ds.dataset_id,
    spath.machine_name AS storage_server_name,
    instname.instrument AS instrument_name,
    instname.instrument_class,
    instname.max_simultaneous_captures,
    ds.capture_subfolder
   FROM ((public.t_dataset ds
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     LEFT JOIN public.t_storage_path spath ON ((spath.storage_path_id = ds.storage_path_id)));


ALTER TABLE cap.v_dms_get_dataset_definition OWNER TO d3l243;

--
-- Name: TABLE v_dms_get_dataset_definition; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dms_get_dataset_definition TO readaccess;

