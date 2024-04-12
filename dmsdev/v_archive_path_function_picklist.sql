--
-- Name: v_archive_path_function_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_path_function_picklist AS
 SELECT apf_function AS name
   FROM public.t_archive_path_function;


ALTER VIEW public.v_archive_path_function_picklist OWNER TO d3l243;

--
-- Name: TABLE v_archive_path_function_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_path_function_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_archive_path_function_picklist TO writeaccess;

