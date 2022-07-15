--
-- Name: v_get_analysis_jobs_for_archive_busy; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_get_analysis_jobs_for_archive_busy AS
 SELECT j.job,
    ds.dataset_id,
    ds.dataset,
    ds.created,
    ds.dataset_state_id
   FROM ((public.t_analysis_job j
     JOIN public.t_dataset_archive da ON ((j.dataset_id = da.dataset_id)))
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
  WHERE ((j.job_state_id = ANY (ARRAY[1, 2, 3, 8])) AND (((ds.dataset OPERATOR(public.~) similar_to_escape('QC[_]%'::text)) AND (da.archive_state_id = 7) AND (da.archive_state_last_affected > (CURRENT_TIMESTAMP - '00:15:00'::interval))) OR ((ds.dataset OPERATOR(public.!~) similar_to_escape('QC[_]%'::text)) AND (da.archive_state_id = 1) AND (da.archive_state_last_affected > (CURRENT_TIMESTAMP - '03:00:00'::interval))) OR ((ds.dataset OPERATOR(public.!~) similar_to_escape('QC[_]%'::text)) AND (da.archive_state_id = ANY (ARRAY[7, 8])) AND (da.archive_state_last_affected > (CURRENT_TIMESTAMP - '02:00:00'::interval))) OR ((ds.dataset OPERATOR(public.!~) similar_to_escape('QC[_]%'::text)) AND (da.archive_state_id = ANY (ARRAY[2, 6])) AND (da.archive_state_last_affected > (CURRENT_TIMESTAMP - '01:00:00'::interval)))));


ALTER TABLE public.v_get_analysis_jobs_for_archive_busy OWNER TO d3l243;

--
-- Name: TABLE v_get_analysis_jobs_for_archive_busy; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_get_analysis_jobs_for_archive_busy TO readaccess;

