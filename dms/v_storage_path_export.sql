--
-- Name: v_storage_path_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_path_export AS
 SELECT t_storage_path.storage_path_id AS id,
    t_storage_path.storage_path AS "Path",
    t_storage_path.machine_name AS machinename,
    t_storage_path.vol_name_client AS volclient,
    t_storage_path.vol_name_server AS volserver,
    t_storage_path.storage_path_function AS "Function",
    t_storage_path.instrument,
    t_storage_path.description,
    t_storage_path.created
   FROM public.t_storage_path;


ALTER TABLE public.v_storage_path_export OWNER TO d3l243;

--
-- Name: TABLE v_storage_path_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_path_export TO readaccess;
GRANT SELECT ON TABLE public.v_storage_path_export TO writeaccess;

