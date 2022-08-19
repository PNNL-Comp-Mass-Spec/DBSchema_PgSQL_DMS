--
-- Name: v_instrument_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_entry AS
 SELECT t_instrument_name.instrument_id AS id,
    t_instrument_name.instrument AS instrument_name,
    t_instrument_name.description,
    t_instrument_name.instrument_class,
    t_instrument_name.instrument_group,
    t_instrument_name.room_number,
    t_instrument_name.capture_method,
    rtrim((t_instrument_name.status)::text) AS status,
    t_instrument_name.usage,
    t_instrument_name.operations_role,
        CASE
            WHEN (COALESCE((t_instrument_name.tracking)::integer, 0) = 0) THEN 'N'::text
            ELSE 'Y'::text
        END AS track_usage_when_inactive,
        CASE
            WHEN (COALESCE((t_instrument_name.scan_source_dir)::integer, 0) = 0) THEN 'N'::text
            ELSE 'Y'::text
        END AS scan_source_dir,
    t_instrument_name.percent_emsl_owned,
    t_instrument_name.source_path_id,
    t_instrument_name.storage_path_id,
        CASE
            WHEN (COALESCE((t_instrument_name.auto_define_storage_path)::integer, 0) = 0) THEN 'N'::text
            ELSE 'Y'::text
        END AS auto_define_storage_path,
    t_instrument_name.auto_sp_vol_name_client,
    t_instrument_name.auto_sp_vol_name_server,
    t_instrument_name.auto_sp_path_root,
    t_instrument_name.auto_sp_url_domain,
    t_instrument_name.auto_sp_archive_server_name,
    t_instrument_name.auto_sp_archive_path_root,
    t_instrument_name.auto_sp_archive_share_path_root
   FROM public.t_instrument_name;


ALTER TABLE public.v_instrument_entry OWNER TO d3l243;

--
-- Name: TABLE v_instrument_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_entry TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_entry TO writeaccess;

