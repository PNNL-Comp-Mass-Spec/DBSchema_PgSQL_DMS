--
-- Name: v_run_factors_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_run_factors_export AS
 SELECT f.name AS factor,
    f.value,
    rr.request_id AS request,
    rr.batch_id AS batch,
    rr.dataset_id,
    ds.dataset,
    COALESCE(dsexp.exp_id, rrexp.exp_id) AS experiment_id,
    COALESCE(dsexp.experiment, rrexp.experiment) AS experiment,
    COALESCE(dscampaign.campaign, rrcampaign.campaign) AS campaign
   FROM ((((((public.t_requested_run rr
     JOIN public.t_factor f ON (((f.target_id = rr.request_id) AND (f.type OPERATOR(public.=) 'Run_Request'::public.citext))))
     JOIN public.t_experiments rrexp ON ((rr.exp_id = rrexp.exp_id)))
     JOIN public.t_campaign rrcampaign ON ((rrcampaign.campaign_id = rrexp.campaign_id)))
     LEFT JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_experiments dsexp ON ((ds.exp_id = dsexp.exp_id)))
     LEFT JOIN public.t_campaign dscampaign ON ((dsexp.campaign_id = dscampaign.campaign_id)));


ALTER TABLE public.v_run_factors_export OWNER TO d3l243;

--
-- Name: TABLE v_run_factors_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_run_factors_export TO readaccess;
GRANT SELECT ON TABLE public.v_run_factors_export TO writeaccess;

