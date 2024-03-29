--
-- Name: v_archive_list_report_2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_list_report_2 AS
 SELECT da.dataset_id AS id,
    ds.dataset,
    instname.instrument,
    dasn.archive_state AS state,
    ausn.archive_update_state AS update_state,
    da.archive_date AS entered,
    da.archive_state_last_affected AS state_last_affected,
    da.archive_update_state_last_affected AS update_state_last_affected,
    archpath.archive_path,
    archpath.archive_server_name AS archive_server,
    spath.machine_name AS storage_server,
    da.instrument_data_purged
   FROM ((((((public.t_dataset_archive da
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
     JOIN public.t_archive_path archpath ON ((da.storage_path_id = archpath.archive_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_archive_update_state_name ausn ON ((da.archive_update_state_id = ausn.archive_update_state_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)));


ALTER VIEW public.v_archive_list_report_2 OWNER TO d3l243;

--
-- Name: TABLE v_archive_list_report_2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_list_report_2 TO readaccess;
GRANT SELECT ON TABLE public.v_archive_list_report_2 TO writeaccess;

