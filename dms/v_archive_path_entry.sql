--
-- Name: v_archive_path_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_path_entry AS
 SELECT archpath.archive_path_id,
    archpath.archive_path,
    archpath.archive_server_name AS server_name,
    instname.instrument AS instrument_name,
    archpath.note,
    archpath.archive_path_function,
    archpath.network_share_path
   FROM (public.t_archive_path archpath
     JOIN public.t_instrument_name instname ON ((archpath.instrument_id = instname.instrument_id)));


ALTER VIEW public.v_archive_path_entry OWNER TO d3l243;

--
-- Name: TABLE v_archive_path_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_path_entry TO readaccess;
GRANT SELECT ON TABLE public.v_archive_path_entry TO writeaccess;

