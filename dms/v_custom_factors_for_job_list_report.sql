--
-- Name: v_custom_factors_for_job_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_custom_factors_for_job_list_report AS
 SELECT j.job,
    tool.analysis_tool AS tool,
    requestfactors.factor,
    requestfactors.value,
    ds.dataset,
    rr.dataset_id,
    rr.request_id AS request,
    COALESCE(dsexp.experiment, rrexp.experiment) AS experiment,
    COALESCE(dscampaign.campaign, rrcampaign.campaign) AS campaign
   FROM (((((((( SELECT f.target_id AS request_id,
            f.name AS factor,
            f.value
           FROM public.t_factor f
          WHERE (f.type OPERATOR(public.=) 'Run_Request'::public.citext)) requestfactors
     JOIN public.t_requested_run rr ON ((requestfactors.request_id = rr.request_id)))
     LEFT JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     JOIN (public.t_campaign rrcampaign
     JOIN public.t_experiments rrexp ON ((rrcampaign.campaign_id = rrexp.campaign_id))) ON ((rr.exp_id = rrexp.exp_id)))
     LEFT JOIN public.t_experiments dsexp ON ((ds.exp_id = dsexp.exp_id)))
     LEFT JOIN public.t_campaign dscampaign ON ((dsexp.campaign_id = dscampaign.campaign_id)))
     JOIN public.t_analysis_job j ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)));


ALTER TABLE public.v_custom_factors_for_job_list_report OWNER TO d3l243;

--
-- Name: TABLE v_custom_factors_for_job_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_custom_factors_for_job_list_report TO readaccess;

