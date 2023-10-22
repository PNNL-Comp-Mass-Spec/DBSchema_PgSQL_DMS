--
-- Name: v_instrument_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_list_report AS
 SELECT instname.instrument_id AS id,
    instname.instrument AS name,
    instname.description,
    instname.instrument_class AS class,
    instname.instrument_group AS "group",
    instname.status,
    instname.usage,
    instname.operations_role AS ops_role,
        CASE
            WHEN (instname.status OPERATOR(public.=) 'active'::public.citext) THEN scansourceyesno.description
            ELSE 'No'::public.citext
        END AS scan_source,
    instgroup.allocation_tag,
    instname.percent_emsl_owned,
    instname.capture_method AS capture,
    instname.room_number AS room,
    (((spath.vol_name_client)::text || (spath.storage_path)::text))::public.citext AS assigned_storage,
    (s.source)::public.citext AS assigned_source,
    definestorageyesno.description AS auto_define_storage,
    (((instname.auto_sp_vol_name_client)::text || (instname.auto_sp_path_root)::text))::public.citext AS auto_storage_path,
    (public.get_instrument_dataset_type_list(instname.instrument_id))::public.citext AS allowed_dataset_types,
    instname.created,
    eusmapping.eus_instrument_id,
    eusmapping.eus_display_name,
    eusmapping.eus_instrument_name,
    eusmapping.local_instrument_name,
        CASE
            WHEN (insttracking.reporting OPERATOR(public.~~) '%E%'::text) THEN 'EUS Primary Instrument'::public.citext
            WHEN (insttracking.reporting OPERATOR(public.~~) '%P%'::text) THEN 'Production operations role'::public.citext
            WHEN (insttracking.reporting OPERATOR(public.~~) '%T%'::text) THEN 'tracking flag enabled'::public.citext
            ELSE ''::public.citext
        END AS usage_tracking_status,
    trackingyesno.description AS track_when_inactive,
    instname.storage_purge_holdoff_months
   FROM ((((((((public.t_instrument_name instname
     JOIN public.t_yes_no definestorageyesno ON ((instname.auto_define_storage_path = definestorageyesno.flag)))
     JOIN public.t_yes_no scansourceyesno ON ((instname.scan_source_dir = scansourceyesno.flag)))
     JOIN public.t_instrument_group instgroup ON ((instname.instrument_group OPERATOR(public.=) instgroup.instrument_group)))
     JOIN public.t_yes_no trackingyesno ON ((instname.tracking = trackingyesno.flag)))
     LEFT JOIN public.t_storage_path spath ON ((instname.storage_path_id = spath.storage_path_id)))
     LEFT JOIN ( SELECT t_storage_path.storage_path_id,
            ((t_storage_path.vol_name_server)::text || (t_storage_path.storage_path)::text) AS source
           FROM public.t_storage_path) s ON ((s.storage_path_id = instname.source_path_id)))
     LEFT JOIN ( SELECT instname_1.instrument_id,
            emslinst.eus_instrument_id,
            emslinst.eus_display_name,
            emslinst.eus_instrument_name,
            emslinst.local_instrument_name
           FROM ((public.t_emsl_dms_instrument_mapping instmapping
             JOIN public.t_emsl_instruments emslinst ON ((instmapping.eus_instrument_id = emslinst.eus_instrument_id)))
             JOIN public.t_instrument_name instname_1 ON ((instmapping.dms_instrument_id = instname_1.instrument_id)))) eusmapping ON ((instname.instrument_id = eusmapping.instrument_id)))
     LEFT JOIN public.v_instrument_tracked insttracking ON ((instname.instrument OPERATOR(public.=) insttracking.name)));


ALTER TABLE public.v_instrument_list_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_list_report TO writeaccess;

