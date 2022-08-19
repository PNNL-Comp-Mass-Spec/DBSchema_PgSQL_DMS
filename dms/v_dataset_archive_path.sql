--
-- Name: v_dataset_archive_path; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_archive_path AS
 SELECT da.dataset_id,
    ap.network_share_path AS archive_path,
    da.instrument_data_purged,
    ap.archive_url
   FROM (public.t_archive_path ap
     JOIN public.t_dataset_archive da ON ((ap.archive_path_id = da.storage_path_id)));


ALTER TABLE public.v_dataset_archive_path OWNER TO d3l243;

--
-- Name: TABLE v_dataset_archive_path; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_archive_path TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_archive_path TO writeaccess;

