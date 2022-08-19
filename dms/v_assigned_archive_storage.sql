--
-- Name: v_assigned_archive_storage; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_assigned_archive_storage AS
 SELECT t_instrument_name.instrument AS instrument_name,
    t_archive_path.archive_path,
    t_archive_path.archive_server_name AS archive_server,
    t_archive_path.archive_path_id
   FROM (public.t_archive_path
     JOIN public.t_instrument_name ON ((t_archive_path.instrument_id = t_instrument_name.instrument_id)))
  WHERE (t_archive_path.archive_path_function OPERATOR(public.=) 'Active'::public.citext);


ALTER TABLE public.v_assigned_archive_storage OWNER TO d3l243;

--
-- Name: TABLE v_assigned_archive_storage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_assigned_archive_storage TO readaccess;
GRANT SELECT ON TABLE public.v_assigned_archive_storage TO writeaccess;

