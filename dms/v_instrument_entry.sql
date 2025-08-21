--
-- Name: v_instrument_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_entry AS
 SELECT instrument_id AS id,
    instrument AS instrument_name,
    description,
    instrument_class,
    instrument_group,
    room_number,
    capture_method,
    rtrim((status)::text) AS status,
    usage,
    operations_role,
        CASE
            WHEN (COALESCE((tracking)::integer, 0) = 0) THEN 'N'::text
            ELSE 'Y'::text
        END AS track_usage_when_inactive,
        CASE
            WHEN (COALESCE((scan_source_dir)::integer, 0) = 0) THEN 'N'::text
            ELSE 'Y'::text
        END AS scan_source_dir,
    percent_emsl_owned,
        CASE
            WHEN service_center_eligible THEN 'Yes'::public.citext
            ELSE 'No'::public.citext
        END AS service_center_eligible,
    source_path_id,
    storage_path_id,
        CASE
            WHEN (COALESCE((auto_define_storage_path)::integer, 0) = 0) THEN 'N'::text
            ELSE 'Y'::text
        END AS auto_define_storage_path,
    auto_sp_vol_name_client,
    auto_sp_vol_name_server,
    auto_sp_path_root,
    auto_sp_url_domain,
    auto_sp_archive_server_name,
    auto_sp_archive_path_root,
    auto_sp_archive_share_path_root
   FROM public.t_instrument_name;


ALTER VIEW public.v_instrument_entry OWNER TO d3l243;

--
-- Name: TABLE v_instrument_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_entry TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_entry TO writeaccess;

