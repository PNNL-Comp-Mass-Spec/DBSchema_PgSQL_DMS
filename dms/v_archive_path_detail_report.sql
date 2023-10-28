--
-- Name: v_archive_path_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_path_detail_report AS
 SELECT archpath.archive_path_id AS id,
    archpath.archive_path,
    archpath.archive_server_name AS archive_server,
    archpath.network_share_path,
    instname.instrument AS instrument_name,
    archpath.note,
    archpath.archive_path_function AS status,
    archpath.archive_url
   FROM (public.t_archive_path archpath
     JOIN public.t_instrument_name instname ON ((archpath.instrument_id = instname.instrument_id)));


ALTER TABLE public.v_archive_path_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_archive_path_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_path_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_archive_path_detail_report TO writeaccess;

