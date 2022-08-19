--
-- Name: v_instrument_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_detail_report AS
 SELECT instname.instrument_id AS id,
    instname.instrument AS name,
    instname.source_path_id,
    s.source AS assigned_source,
    instname.storage_path_id,
    ((spath.vol_name_client)::text || (spath.storage_path)::text) AS assigned_storage,
    ap.archive_path AS assigned_archive_path,
    ap.network_share_path AS archive_share_path,
    instname.description,
    instname.instrument_class AS class,
    instname.instrument_group,
    instname.room_number AS room,
    instname.capture_method AS capture,
    instname.status,
    instname.usage,
    instname.operations_role AS ops_role,
    trackingyesno.description AS track_usage_when_inactive,
        CASE
            WHEN (instname.status = 'active'::bpchar) THEN scansourceyesno.description
            ELSE 'No (not active)'::public.citext
        END AS scan_source,
    instgroup.allocation_tag,
    instname.percent_emsl_owned,
    public.get_instrument_dataset_type_list(instname.instrument_id) AS allowed_dataset_types,
    instname.created,
    definestorageyesno.description AS auto_define_storage,
    ((instname.auto_sp_vol_name_client)::text || (instname.auto_sp_path_root)::text) AS auto_defined_storage_path_root,
    ((instname.auto_sp_vol_name_server)::text || (instname.auto_sp_path_root)::text) AS auto_defined_storage_path_on_server,
    instname.auto_sp_url_domain AS auto_defined_url_domain,
    ((instname.auto_sp_archive_server_name)::text || (instname.auto_sp_archive_path_root)::text) AS auto_defined_archive_path_root,
    instname.auto_sp_archive_share_path_root AS auto_defined_archive_share_path_root,
    eusmapping.eus_instrument_id,
    eusmapping.eus_display_name,
    eusmapping.eus_instrument_name,
    eusmapping.local_instrument_name,
        CASE
            WHEN (insttracking.reporting ~~ '%E%'::text) THEN 'EUS Primary Instrument'::text
            WHEN (insttracking.reporting ~~ '%P%'::text) THEN 'Production operations role'::text
            WHEN (insttracking.reporting ~~ '%T%'::text) THEN 'tracking flag enabled'::text
            ELSE ''::text
        END AS usage_tracking_status,
    instname.default_purge_policy,
    instname.default_purge_priority,
    instname.storage_purge_holdoff_months
   FROM (((((((((public.t_instrument_name instname
     LEFT JOIN public.t_storage_path spath ON ((instname.storage_path_id = spath.storage_path_id)))
     LEFT JOIN ( SELECT t_storage_path.storage_path_id,
            ((t_storage_path.vol_name_server)::text || (t_storage_path.storage_path)::text) AS source
           FROM public.t_storage_path) s ON ((s.storage_path_id = instname.source_path_id)))
     JOIN public.t_yes_no definestorageyesno ON ((instname.auto_define_storage_path = definestorageyesno.flag)))
     JOIN public.t_yes_no scansourceyesno ON ((instname.scan_source_dir = scansourceyesno.flag)))
     JOIN public.t_instrument_group instgroup ON ((instname.instrument_group OPERATOR(public.=) instgroup.instrument_group)))
     JOIN public.t_yes_no trackingyesno ON ((instname.tracking = trackingyesno.flag)))
     LEFT JOIN public.t_archive_path ap ON (((ap.instrument_id = instname.instrument_id) AND (ap.archive_path_function OPERATOR(public.=) 'active'::public.citext))))
     LEFT JOIN ( SELECT instname_1.instrument_id,
            emslinst.eus_instrument_id,
            emslinst.eus_display_name,
            emslinst.eus_instrument_name,
            emslinst.local_instrument_name
           FROM ((public.t_emsl_dms_instrument_mapping instmapping
             JOIN public.t_emsl_instruments emslinst ON ((instmapping.eus_instrument_id = emslinst.eus_instrument_id)))
             JOIN public.t_instrument_name instname_1 ON ((instmapping.dms_instrument_id = instname_1.instrument_id)))) eusmapping ON ((instname.instrument_id = eusmapping.instrument_id)))
     LEFT JOIN public.v_instrument_tracked insttracking ON ((instname.instrument OPERATOR(public.=) insttracking.name)));


ALTER TABLE public.v_instrument_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_detail_report TO writeaccess;

