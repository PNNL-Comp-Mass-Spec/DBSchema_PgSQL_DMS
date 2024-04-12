--
-- Name: v_misc_paths; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_misc_paths AS
 SELECT path_function,
    client,
    server,
    comment
   FROM public.t_misc_paths;


ALTER VIEW public.v_misc_paths OWNER TO d3l243;

--
-- Name: TABLE v_misc_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_misc_paths TO readaccess;
GRANT SELECT ON TABLE public.v_misc_paths TO writeaccess;

