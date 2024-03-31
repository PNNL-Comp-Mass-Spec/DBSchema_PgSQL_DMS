--
-- Name: v_purgeable_datasets_nointerest_norecentjob; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_purgeable_datasets_nointerest_norecentjob AS
 SELECT dataset_id,
    storage_server_name,
    server_vol,
    created,
    raw_data_type,
    stage_md5_required,
    most_recent_job,
    purge_priority,
    archive_state_id
   FROM public.v_purgeable_datasets_nointerest
  WHERE (most_recent_job < (CURRENT_TIMESTAMP - '60 days'::interval));


ALTER VIEW public.v_purgeable_datasets_nointerest_norecentjob OWNER TO d3l243;

--
-- Name: TABLE v_purgeable_datasets_nointerest_norecentjob; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_purgeable_datasets_nointerest_norecentjob TO readaccess;
GRANT SELECT ON TABLE public.v_purgeable_datasets_nointerest_norecentjob TO writeaccess;

