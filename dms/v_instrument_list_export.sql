--
-- Name: v_instrument_list_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_list_export AS
 SELECT inst.instrument_id AS id,
    inst.instrument AS name,
    inst.description,
    inst.room_number AS room,
    inst.usage,
    inst.operations_role AS ops_role,
    inst.status,
    inst.instrument_class AS class,
    inst.instrument_group,
    inst.capture_method AS capture,
    instclass.raw_data_type,
    srcpath.source_path,
    storagepath.storage_path,
    instclass.is_purgeable,
    instclass.requires_preparation,
    inst.percent_emsl_owned
   FROM (((public.t_instrument_name inst
     JOIN ( SELECT t_storage_path.storage_path_id,
            ((t_storage_path.vol_name_client)::text || (t_storage_path.storage_path)::text) AS storage_path
           FROM public.t_storage_path) storagepath ON ((inst.storage_path_id = storagepath.storage_path_id)))
     JOIN ( SELECT t_storage_path.storage_path_id,
            ((t_storage_path.vol_name_server)::text || (t_storage_path.storage_path)::text) AS source_path
           FROM public.t_storage_path) srcpath ON ((srcpath.storage_path_id = inst.source_path_id)))
     JOIN public.t_instrument_class instclass ON ((inst.instrument_class OPERATOR(public.=) instclass.instrument_class)));


ALTER VIEW public.v_instrument_list_export OWNER TO d3l243;

--
-- Name: TABLE v_instrument_list_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_list_export TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_list_export TO writeaccess;

