--
-- Name: v_archive_path_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_path_entry AS
 SELECT tap.archive_path_id,
    tap.archive_path,
    tap.archive_server_name AS server_name,
    tin.instrument AS instrument_name,
    tap.note,
    tap.archive_path_function,
    tap.network_share_path
   FROM (public.t_archive_path tap
     JOIN public.t_instrument_name tin ON ((tap.instrument_id = tin.instrument_id)));


ALTER TABLE public.v_archive_path_entry OWNER TO d3l243;

--
-- Name: TABLE v_archive_path_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_path_entry TO readaccess;
GRANT SELECT ON TABLE public.v_archive_path_entry TO writeaccess;

