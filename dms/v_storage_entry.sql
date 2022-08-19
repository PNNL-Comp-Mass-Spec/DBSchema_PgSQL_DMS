--
-- Name: v_storage_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_entry AS
 SELECT t_storage_path.storage_path,
    t_storage_path.vol_name_client,
    t_storage_path.vol_name_server,
    t_storage_path.storage_path_function,
    t_storage_path.instrument,
    t_storage_path.description,
    t_storage_path.storage_path_id
   FROM public.t_storage_path;


ALTER TABLE public.v_storage_entry OWNER TO d3l243;

--
-- Name: TABLE v_storage_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_entry TO readaccess;
GRANT SELECT ON TABLE public.v_storage_entry TO writeaccess;

