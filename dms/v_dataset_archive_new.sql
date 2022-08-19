--
-- Name: v_dataset_archive_new; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_archive_new AS
 SELECT ds.dataset,
    ds.folder_name,
    spath.vol_name_server AS server_vol,
    spath.vol_name_client AS client_vol,
    spath.storage_path,
    archpath.archive_path,
    instname.instrument_class,
    da.last_update
   FROM ((((public.t_dataset ds
     JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_archive_path archpath ON ((da.storage_path_id = archpath.archive_path_id)))
  WHERE (da.archive_state_id = 1);


ALTER TABLE public.v_dataset_archive_new OWNER TO d3l243;

--
-- Name: TABLE v_dataset_archive_new; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_archive_new TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_archive_new TO writeaccess;

