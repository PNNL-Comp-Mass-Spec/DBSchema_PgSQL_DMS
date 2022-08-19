--
-- Name: v_misc_paths; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_misc_paths AS
 SELECT t_misc_paths.path_function,
    t_misc_paths.client,
    t_misc_paths.server,
    t_misc_paths.comment
   FROM public.t_misc_paths;


ALTER TABLE public.v_misc_paths OWNER TO d3l243;

--
-- Name: TABLE v_misc_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_misc_paths TO readaccess;
GRANT SELECT ON TABLE public.v_misc_paths TO writeaccess;

