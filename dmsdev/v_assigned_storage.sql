--
-- Name: v_assigned_storage; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_assigned_storage AS
 SELECT t_instrument_name.instrument,
    t_instrument_name.capture_method,
    vs.vol_name_server AS source_vol,
    vs.storage_path AS source_path,
    vr.vol_name_client AS client_storage_vol,
    vr.vol_name_server AS server_storage_vol,
    vr.storage_path,
    t_instrument_name.source_path_id,
    t_instrument_name.storage_path_id,
    t_instrument_name.instrument_id,
    vr.machine_name
   FROM ((public.t_instrument_name
     JOIN ( SELECT t_storage_path.storage_path_id,
            t_storage_path.storage_path,
            t_storage_path.vol_name_server
           FROM public.t_storage_path
          WHERE (t_storage_path.storage_path_function OPERATOR(public.=) 'inbox'::public.citext)) vs ON ((t_instrument_name.source_path_id = vs.storage_path_id)))
     JOIN ( SELECT t_storage_path.storage_path_id,
            t_storage_path.storage_path,
            t_storage_path.vol_name_client,
            t_storage_path.vol_name_server,
            t_storage_path.machine_name
           FROM public.t_storage_path
          WHERE (t_storage_path.storage_path_function OPERATOR(public.=) 'raw-storage'::public.citext)) vr ON ((t_instrument_name.storage_path_id = vr.storage_path_id)));


ALTER VIEW public.v_assigned_storage OWNER TO d3l243;

--
-- Name: TABLE v_assigned_storage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_assigned_storage TO readaccess;
GRANT SELECT ON TABLE public.v_assigned_storage TO writeaccess;

