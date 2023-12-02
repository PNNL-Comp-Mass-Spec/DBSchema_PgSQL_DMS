--
-- Name: v_cached_dataset_links; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_cached_dataset_links AS
 SELECT l.dataset_id,
    d.dataset,
    l.dataset_row_version,
    l.storage_path_row_version,
    l.dataset_folder_path,
    l.archive_folder_path,
    l.myemsl_url,
    l.qc_link,
    l.qc_2d,
    l.qc_metric_stats,
    l.masic_directory_name,
    l.update_required,
    l.last_affected
   FROM (public.t_cached_dataset_links l
     JOIN public.t_dataset d ON ((d.dataset_id = l.dataset_id)));


ALTER VIEW public.v_cached_dataset_links OWNER TO d3l243;

--
-- Name: TABLE v_cached_dataset_links; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_cached_dataset_links TO readaccess;
GRANT SELECT ON TABLE public.v_cached_dataset_links TO writeaccess;

