--
-- Name: v_purgeable_datasets_nojob; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_purgeable_datasets_nojob AS
 SELECT ds.dataset_id,
    spath.machine_name AS storage_server_name,
    spath.vol_name_server AS server_vol,
    ds.created,
    instclass.raw_data_type,
    da.stagemd5_required AS stage_md5_required,
    da.purge_priority,
    da.archive_state_id
   FROM (((((public.t_dataset ds
     JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_instrument_class instclass ON ((instname.instrument_class OPERATOR(public.=) instclass.instrument_class)))
     LEFT JOIN public.t_analysis_job j ON ((ds.dataset_id = j.dataset_id)))
  WHERE ((instclass.is_purgeable > 0) AND (j.dataset_id IS NULL) AND ((da.archive_state_id = 3) OR ((da.archive_state_id = 15) AND (da.purge_policy = 2))) AND (ds.dataset_rating_id <> ALL (ARRAY['-2'::integer, '-10'::integer])) AND ((COALESCE((da.purge_holdoff_date)::timestamp with time zone, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP) OR (da.stagemd5_required > 0)) AND ((da.archive_update_state_id = 4) OR ((da.archive_update_state_id = ANY (ARRAY[2, 3, 5])) AND (da.archive_update_state_last_affected < (CURRENT_TIMESTAMP - '60 days'::interval)))));


ALTER TABLE public.v_purgeable_datasets_nojob OWNER TO d3l243;

--
-- Name: VIEW v_purgeable_datasets_nojob; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_purgeable_datasets_nojob IS 'This view is used by RequestPurgeTask';

--
-- Name: TABLE v_purgeable_datasets_nojob; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_purgeable_datasets_nojob TO readaccess;

