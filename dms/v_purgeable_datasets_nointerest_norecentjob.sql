--
-- Name: v_purgeable_datasets_nointerest_norecentjob; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_purgeable_datasets_nointerest_norecentjob AS
 SELECT v_purgeable_datasets_nointerest.dataset_id,
    v_purgeable_datasets_nointerest.storage_server_name,
    v_purgeable_datasets_nointerest.server_vol,
    v_purgeable_datasets_nointerest.created,
    v_purgeable_datasets_nointerest.raw_data_type,
    v_purgeable_datasets_nointerest.stage_md5_required,
    v_purgeable_datasets_nointerest.most_recent_job,
    v_purgeable_datasets_nointerest.purge_priority,
    v_purgeable_datasets_nointerest.archive_state_id
   FROM public.v_purgeable_datasets_nointerest
  WHERE (v_purgeable_datasets_nointerest.most_recent_job < (CURRENT_TIMESTAMP - '60 days'::interval));


ALTER VIEW public.v_purgeable_datasets_nointerest_norecentjob OWNER TO d3l243;

--
-- Name: TABLE v_purgeable_datasets_nointerest_norecentjob; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_purgeable_datasets_nointerest_norecentjob TO readaccess;
GRANT SELECT ON TABLE public.v_purgeable_datasets_nointerest_norecentjob TO writeaccess;

