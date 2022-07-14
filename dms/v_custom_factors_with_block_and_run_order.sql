--
-- Name: v_custom_factors_with_block_and_run_order; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_custom_factors_with_block_and_run_order AS
 SELECT f.factor,
    f.value,
    rr.request_id AS request,
    rr.batch_id AS batch,
    rr.dataset_id,
    ds.dataset,
    COALESCE(dsexp.exp_id, rrexp.exp_id) AS experiment_id,
    COALESCE(dsexp.experiment, rrexp.experiment) AS experiment,
    COALESCE(dscampaign.campaign, rrcampaign.campaign) AS campaign
   FROM (((((( SELECT f_1.target_id AS request_id,
            f_1.name AS factor,
            f_1.value
           FROM public.t_factor f_1
          WHERE (f_1.type OPERATOR(public.=) 'Run_Request'::public.citext)
        UNION
         SELECT t_requested_run.request_id,
            'Block'::public.citext AS factor,
            (t_requested_run.block)::public.citext AS value
           FROM public.t_requested_run
          WHERE (NOT (t_requested_run.block IS NULL))
        UNION
         SELECT t_requested_run.request_id,
            'Requested_Run_Order'::public.citext AS factor,
            (t_requested_run.run_order)::public.citext AS value
           FROM public.t_requested_run
          WHERE (NOT (t_requested_run.run_order IS NULL))) f
     JOIN public.t_requested_run rr ON ((f.request_id = rr.request_id)))
     LEFT JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     JOIN (public.t_campaign rrcampaign
     JOIN public.t_experiments rrexp ON ((rrcampaign.campaign_id = rrexp.campaign_id))) ON ((rr.exp_id = rrexp.exp_id)))
     LEFT JOIN public.t_experiments dsexp ON ((ds.exp_id = dsexp.exp_id)))
     LEFT JOIN public.t_campaign dscampaign ON ((dsexp.campaign_id = dscampaign.campaign_id)));


ALTER TABLE public.v_custom_factors_with_block_and_run_order OWNER TO d3l243;

--
-- Name: TABLE v_custom_factors_with_block_and_run_order; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_custom_factors_with_block_and_run_order TO readaccess;

