--
-- Name: v_purgeable_datasets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_purgeable_datasets AS
 SELECT ds.dataset_id,
    spath.machine_name AS storage_server_name,
    spath.vol_name_server AS server_vol,
    max(COALESCE(aj.start, aj.created)) AS most_recent_job,
    instclass.raw_data_type,
    da.stagemd5_required AS stage_md5_required,
    da.purge_priority,
    da.archive_state_id
   FROM (((((public.t_dataset ds
     JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_analysis_job aj ON ((ds.dataset_id = aj.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_instrument_class instclass ON ((instname.instrument_class OPERATOR(public.=) instclass.instrument_class)))
  WHERE ((instclass.is_purgeable > 0) AND ((da.archive_state_id = 3) OR ((da.archive_state_id = 15) AND (da.purge_policy = 2))) AND (ds.dataset_rating_id <> ALL (ARRAY['-2'::integer, '-10'::integer])) AND ((COALESCE((da.purge_holdoff_date)::timestamp with time zone, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP) OR (da.stagemd5_required > 0)) AND ((da.archive_update_state_id = 4) OR ((da.archive_update_state_id = ANY (ARRAY[2, 3, 5])) AND (da.archive_update_state_last_affected < (CURRENT_TIMESTAMP - '60 days'::interval)))) AND (NOT (EXISTS ( SELECT inprogressjobs.job
           FROM public.t_analysis_job inprogressjobs
          WHERE ((inprogressjobs.job_state_id = ANY (ARRAY[1, 2, 3, 8, 9, 10, 11, 12, 16, 17, 19])) AND (inprogressjobs.dataset_id = ds.dataset_id))))))
  GROUP BY ds.dataset_id, spath.machine_name, spath.vol_name_server, instclass.raw_data_type, da.stagemd5_required, da.purge_priority, da.archive_state_id;


ALTER VIEW public.v_purgeable_datasets OWNER TO d3l243;

--
-- Name: VIEW v_purgeable_datasets; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_purgeable_datasets IS 'When coalescing dates to find the most recent job, use AJ.start and not AJ.finish because if a job gets re-run, the start time remains unchanged, but the finish time gets updated';

--
-- Name: TABLE v_purgeable_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_purgeable_datasets TO readaccess;
GRANT SELECT ON TABLE public.v_purgeable_datasets TO writeaccess;

