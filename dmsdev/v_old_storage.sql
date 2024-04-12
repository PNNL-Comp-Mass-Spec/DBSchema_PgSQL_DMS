--
-- Name: v_old_storage; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_old_storage AS
 SELECT storage_path_id,
    storage_path,
    vol_name_client,
    vol_name_server,
    storage_path_function,
    instrument
   FROM public.t_storage_path
  WHERE (storage_path_function OPERATOR(public.=) 'old-storage'::public.citext);


ALTER VIEW public.v_old_storage OWNER TO d3l243;

--
-- Name: TABLE v_old_storage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_old_storage TO readaccess;
GRANT SELECT ON TABLE public.v_old_storage TO writeaccess;

