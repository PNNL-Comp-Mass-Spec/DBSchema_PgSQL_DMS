--
-- Name: v_dataset_archive_state; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_archive_state AS
 SELECT ds.dataset,
    dasn.archive_state AS state,
    ds.folder_name,
    spath.vol_name_server AS server_vol,
    spath.vol_name_client AS client_vol,
    spath.storage_path,
    archpath.archive_path,
    instname.instrument_class,
    da.last_update,
    instname.instrument AS instrument_name
   FROM (((((public.t_dataset ds
     JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_archive_path archpath ON ((da.storage_path_id = archpath.archive_path_id)))
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)));


ALTER TABLE public.v_dataset_archive_state OWNER TO d3l243;

--
-- Name: TABLE v_dataset_archive_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_archive_state TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_archive_state TO writeaccess;

