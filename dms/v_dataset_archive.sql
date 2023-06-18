--
-- Name: v_dataset_archive; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_archive AS
 SELECT da.dataset_id,
    ds.dataset,
    da.archive_state_id,
    dasn.archive_state,
    da.archive_state_last_affected,
    da.storage_path_id,
    da.archive_date,
    da.last_update,
    da.last_verify,
    da.archive_update_state_id,
    ausn.archive_update_state,
    da.archive_update_state_last_affected,
    da.purge_holdoff_date,
    da.archive_processor,
    da.update_processor,
    da.verification_processor,
    instname.instrument,
    da.instrument_data_purged,
    da.last_successful_archive,
    da.stagemd5_required,
    da.qc_data_purged,
    da.purge_policy,
    da.purge_priority,
    da.myemsl_state,
    COALESCE(public.combine_paths((spath.vol_name_client)::text, public.combine_paths((spath.storage_path)::text, (COALESCE(ds.folder_name, ds.dataset))::text)), ''::text) AS dataset_folder_path,
    ap.archive_path,
    ap.network_share_path
   FROM ((((((public.t_dataset_archive da
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
     JOIN public.t_dataset_archive_update_state_name ausn ON ((da.archive_update_state_id = ausn.archive_update_state_id)))
     JOIN public.t_archive_path ap ON ((da.storage_path_id = ap.archive_path_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)));


ALTER TABLE public.v_dataset_archive OWNER TO d3l243;

--
-- Name: TABLE v_dataset_archive; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_archive TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_archive TO writeaccess;

