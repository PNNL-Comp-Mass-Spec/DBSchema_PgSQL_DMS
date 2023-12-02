--
-- Name: v_archive_path_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_path_list_report AS
 SELECT archpath.archive_path_id AS path_id,
    instname.instrument AS instrument_name,
    archpath.archive_path,
    archpath.archive_server_name AS archive_server,
    archpath.archive_path_function AS archive_path_status,
    count(da.dataset_id) AS datasets,
    instname.description,
    archpath.network_share_path AS archive_share_path,
    archpath.archive_url,
    archpath.created
   FROM ((public.t_instrument_name instname
     JOIN public.t_archive_path archpath ON ((instname.instrument_id = archpath.instrument_id)))
     LEFT JOIN public.t_dataset_archive da ON ((archpath.archive_path_id = da.storage_path_id)))
  GROUP BY archpath.archive_path_id, instname.instrument, archpath.archive_path, archpath.archive_server_name, archpath.archive_path_function, instname.description, archpath.network_share_path, archpath.archive_url, archpath.created;


ALTER VIEW public.v_archive_path_list_report OWNER TO d3l243;

--
-- Name: TABLE v_archive_path_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_path_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_archive_path_list_report TO writeaccess;

