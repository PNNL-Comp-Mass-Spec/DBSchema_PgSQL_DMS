--
-- Name: v_dataset_folder_paths; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_folder_paths AS
 SELECT ds.dataset,
    ds.dataset_id,
    dfpcache.dataset_folder_path,
    dfpcache.archive_folder_path,
    dfpcache.myemsl_path_flag,
    dfpcache.dataset_url,
    da.instrument_data_purged
   FROM ((public.t_dataset ds
     JOIN public.t_cached_dataset_folder_paths dfpcache ON ((ds.dataset_id = dfpcache.dataset_id)))
     LEFT JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)));


ALTER TABLE public.v_dataset_folder_paths OWNER TO d3l243;

--
-- Name: TABLE v_dataset_folder_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_folder_paths TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_folder_paths TO writeaccess;

