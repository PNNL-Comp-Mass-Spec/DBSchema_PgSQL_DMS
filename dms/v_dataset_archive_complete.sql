--
-- Name: v_dataset_archive_complete; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_archive_complete AS
 SELECT v_dataset_archive.dataset,
    v_dataset_archive.folder_name,
    v_dataset_archive.server_vol,
    v_dataset_archive.client_vol,
    v_dataset_archive.storage_path,
    v_dataset_archive.archive_path,
    v_dataset_archive.instrument_class,
    v_dataset_archive.last_update
   FROM public.v_dataset_archive
  WHERE (v_dataset_archive.archive_state = 3);


ALTER TABLE public.v_dataset_archive_complete OWNER TO d3l243;

--
-- Name: TABLE v_dataset_archive_complete; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_archive_complete TO readaccess;

