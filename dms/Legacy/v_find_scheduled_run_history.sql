--
-- Name: v_find_scheduled_run_history; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_find_scheduled_run_history AS
 SELECT rr.request_id,
    rr.request_name,
    rr.created AS req_created,
    e.experiment,
    ds.dataset,
    ds.created,
    rr.work_package,
    t_campaign.campaign,
    rr.requester_username AS requester,
    rr.instrument_group AS instrument,
    dtn.dataset_type AS run_type,
    rr.comment,
    rr.batch_id AS batch,
    rr.blocking_factor
   FROM ((((public.t_requested_run rr
     JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_type_name dtn ON ((rr.request_type_id = dtn.dataset_type_id)))
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
     JOIN public.t_campaign ON ((e.campaign_id = t_campaign.campaign_id)));


ALTER VIEW public.v_find_scheduled_run_history OWNER TO d3l243;

--
-- Name: TABLE v_find_scheduled_run_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_find_scheduled_run_history TO readaccess;
GRANT SELECT ON TABLE public.v_find_scheduled_run_history TO writeaccess;

