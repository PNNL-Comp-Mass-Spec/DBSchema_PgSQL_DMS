--
-- Name: v_dataset_archive_ex; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_archive_ex AS
 SELECT ds.dataset_id,
    ds.dataset,
    ds.folder_name,
    ((spath.vol_name_server)::text || (spath.storage_path)::text) AS server_path,
    ((spath.vol_name_client)::text || (spath.storage_path)::text) AS client_path,
    archpath.archive_path,
    archpath.archive_server_name AS archive_server,
    instname.instrument_class,
    da.last_update,
    da.archive_state_id AS archive_state,
    da.archive_update_state_id AS update_state,
    instname.instrument AS instrument_name,
    da.last_verify,
    instclass.requires_preparation AS requires_prep,
    instclass.is_purgeable
   FROM (((((public.t_dataset ds
     JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_archive_path archpath ON ((da.storage_path_id = archpath.archive_path_id)))
     JOIN public.t_instrument_class instclass ON ((instname.instrument_class OPERATOR(public.=) instclass.instrument_class)));


ALTER VIEW public.v_dataset_archive_ex OWNER TO d3l243;

--
-- Name: TABLE v_dataset_archive_ex; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_archive_ex TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_archive_ex TO writeaccess;

