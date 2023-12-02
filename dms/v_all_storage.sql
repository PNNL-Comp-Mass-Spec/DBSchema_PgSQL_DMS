--
-- Name: v_all_storage; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_all_storage AS
 SELECT t_storage_path.storage_path_id,
    t_storage_path.storage_path,
    t_storage_path.vol_name_client,
    t_storage_path.vol_name_server,
    t_storage_path.storage_path_function
   FROM public.t_storage_path
  WHERE (t_storage_path.storage_path_function OPERATOR(public.~~) '%storage%'::public.citext);


ALTER VIEW public.v_all_storage OWNER TO d3l243;

--
-- Name: TABLE v_all_storage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_all_storage TO readaccess;
GRANT SELECT ON TABLE public.v_all_storage TO writeaccess;

