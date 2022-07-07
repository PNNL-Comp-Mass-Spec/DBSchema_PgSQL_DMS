--
-- Name: v_archive_path_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_path_list_report AS
 SELECT tap.archive_path_id AS path_id,
    tin.instrument AS instrument_name,
    tap.archive_path,
    tap.archive_server_name AS archive_server,
    tap.archive_path_function AS archive_path_status,
    count(da.dataset_id) AS datasets,
    tin.description,
    tap.network_share_path AS archive_share_path,
    tap.archive_url,
    tap.created
   FROM ((public.t_instrument_name tin
     JOIN public.t_archive_path tap ON ((tin.instrument_id = tap.instrument_id)))
     LEFT JOIN public.t_dataset_archive da ON ((tap.archive_path_id = da.storage_path_id)))
  GROUP BY tap.archive_path_id, tin.instrument, tap.archive_path, tap.archive_server_name, tap.archive_path_function, tin.description, tap.network_share_path, tap.archive_url, tap.created;


ALTER TABLE public.v_archive_path_list_report OWNER TO d3l243;

--
-- Name: TABLE v_archive_path_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_path_list_report TO readaccess;

