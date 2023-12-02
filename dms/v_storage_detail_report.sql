--
-- Name: v_storage_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_detail_report AS
 SELECT t_storage_path.storage_path_id AS id,
    t_storage_path.storage_path AS path,
    t_storage_path.vol_name_client AS vol_client,
    t_storage_path.vol_name_server AS vol_server,
    t_storage_path.storage_path_function,
    t_storage_path.instrument,
    t_storage_path.description
   FROM public.t_storage_path;


ALTER VIEW public.v_storage_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_storage_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_storage_detail_report TO writeaccess;

