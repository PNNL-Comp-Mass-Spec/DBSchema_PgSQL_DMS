--
-- Name: v_storage_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_entry AS
 SELECT storage_path,
    vol_name_client,
    vol_name_server,
    storage_path_function,
    instrument,
    description,
    storage_path_id
   FROM public.t_storage_path;


ALTER VIEW public.v_storage_entry OWNER TO d3l243;

--
-- Name: TABLE v_storage_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_entry TO readaccess;
GRANT SELECT ON TABLE public.v_storage_entry TO writeaccess;

