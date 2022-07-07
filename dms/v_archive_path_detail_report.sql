--
-- Name: v_archive_path_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_path_detail_report AS
 SELECT tap.archive_path_id AS id,
    tap.archive_path,
    tap.archive_server_name AS archive_server,
    tap.network_share_path,
    tin.instrument AS instrument_name,
    tap.note,
    tap.archive_path_function AS status,
    tap.archive_url
   FROM (public.t_archive_path tap
     JOIN public.t_instrument_name tin ON ((tap.instrument_id = tin.instrument_id)));


ALTER TABLE public.v_archive_path_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_archive_path_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_path_detail_report TO readaccess;

