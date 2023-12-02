--
-- Name: v_assigned_storage_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_assigned_storage_report AS
 SELECT t_instrument_name.instrument,
    ((storage.vol_name_client)::text || (storage.storage_path)::text) AS storage_path,
    ((src.vol_name_server)::text || (src.storage_path)::text) AS source_path,
    t_instrument_name.capture_method
   FROM ((public.t_instrument_name
     JOIN ( SELECT t_storage_path.storage_path_id,
            t_storage_path.storage_path,
            t_storage_path.vol_name_server
           FROM public.t_storage_path
          WHERE (t_storage_path.storage_path_function OPERATOR(public.=) 'inbox'::public.citext)) src ON ((t_instrument_name.source_path_id = src.storage_path_id)))
     JOIN ( SELECT t_storage_path.storage_path_id,
            t_storage_path.storage_path,
            t_storage_path.vol_name_client,
            t_storage_path.vol_name_server
           FROM public.t_storage_path
          WHERE (t_storage_path.storage_path_function OPERATOR(public.=) 'raw-storage'::public.citext)) storage ON ((t_instrument_name.storage_path_id = storage.storage_path_id)));


ALTER VIEW public.v_assigned_storage_report OWNER TO d3l243;

--
-- Name: TABLE v_assigned_storage_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_assigned_storage_report TO readaccess;
GRANT SELECT ON TABLE public.v_assigned_storage_report TO writeaccess;

