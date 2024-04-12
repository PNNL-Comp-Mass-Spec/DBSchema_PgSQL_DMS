--
-- Name: v_storage_path_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_path_export AS
 SELECT storage_path_id AS id,
    storage_path,
    machine_name,
    vol_name_client AS vol_client,
    vol_name_server AS vol_server,
    storage_path_function,
    instrument,
    description,
    created
   FROM public.t_storage_path;


ALTER VIEW public.v_storage_path_export OWNER TO d3l243;

--
-- Name: TABLE v_storage_path_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_path_export TO readaccess;
GRANT SELECT ON TABLE public.v_storage_path_export TO writeaccess;

