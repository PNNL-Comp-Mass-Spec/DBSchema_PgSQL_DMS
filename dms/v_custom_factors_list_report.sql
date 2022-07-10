--
-- Name: v_custom_factors_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_custom_factors_list_report AS
 SELECT rr.batch_id AS batch,
    rr.request_id AS request,
    requestfactors.factor,
    requestfactors.value,
    rr.dataset_id,
    ds.dataset,
    COALESCE(dsexp.exp_id, rrexp.exp_id) AS experiment_id,
    COALESCE(dsexp.experiment, rrexp.experiment) AS experiment,
    COALESCE(dscampaign.campaign, rrcampaign.campaign) AS campaign
   FROM (((((( SELECT f.target_id AS requestid,
            f.name AS factor,
            f.value
           FROM public.t_factor f
          WHERE (f.type OPERATOR(public.=) 'Run_Request'::public.citext)) requestfactors
     JOIN public.t_requested_run rr ON ((requestfactors.requestid = rr.request_id)))
     LEFT JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     JOIN (public.t_campaign rrcampaign
     JOIN public.t_experiments rrexp ON ((rrcampaign.campaign_id = rrexp.campaign_id))) ON ((rr.exp_id = rrexp.exp_id)))
     LEFT JOIN public.t_experiments dsexp ON ((ds.exp_id = dsexp.exp_id)))
     LEFT JOIN public.t_campaign dscampaign ON ((dsexp.campaign_id = dscampaign.campaign_id)));


ALTER TABLE public.v_custom_factors_list_report OWNER TO d3l243;

--
-- Name: TABLE v_custom_factors_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_custom_factors_list_report TO readaccess;

