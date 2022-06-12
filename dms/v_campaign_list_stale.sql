--
-- Name: v_campaign_list_stale; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_campaign_list_stale AS
 SELECT c.campaign_id,
    c.campaign,
    c.state,
    ct.most_recent_activity,
    ct.sample_prep_request_most_recent AS most_recent_sample_prep_request,
    ct.experiment_most_recent AS most_recent_experiment,
    ct.run_request_most_recent AS most_recent_run_request,
    ct.dataset_most_recent AS most_recent_dataset,
    ct.job_most_recent AS most_recent_analysis_job,
    c.created
   FROM (public.t_campaign c
     LEFT JOIN public.t_campaign_tracking ct ON ((ct.campaign_id = c.campaign_id)))
  WHERE ((COALESCE(ct.sample_prep_request_most_recent, '2000-01-01 00:00:00'::timestamp without time zone) <= (CURRENT_TIMESTAMP + '-1 years -6 mons'::interval)) AND (COALESCE(ct.experiment_most_recent, '2000-01-01 00:00:00'::timestamp without time zone) <= (CURRENT_TIMESTAMP + '-1 years -6 mons'::interval)) AND (COALESCE(ct.run_request_most_recent, '2000-01-01 00:00:00'::timestamp without time zone) <= (CURRENT_TIMESTAMP + '-1 years -6 mons'::interval)) AND (COALESCE(ct.dataset_most_recent, '2000-01-01 00:00:00'::timestamp without time zone) <= (CURRENT_TIMESTAMP + '-1 years -6 mons'::interval)) AND (COALESCE(ct.job_most_recent, '2000-01-01 00:00:00'::timestamp without time zone) <= (CURRENT_TIMESTAMP + '-1 years -6 mons'::interval)) AND (c.created < (CURRENT_TIMESTAMP + '-7 years'::interval)));


ALTER TABLE public.v_campaign_list_stale OWNER TO d3l243;

--
-- Name: TABLE v_campaign_list_stale; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_campaign_list_stale TO readaccess;

