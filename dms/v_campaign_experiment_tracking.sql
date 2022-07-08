--
-- Name: v_campaign_experiment_tracking; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_campaign_experiment_tracking AS
 SELECT e.experiment,
    count(ds.dataset_id) AS datasets,
    e.reason,
    e.created,
    c.campaign AS "#CName"
   FROM ((public.t_campaign c
     JOIN public.t_experiments e ON ((c.campaign_id = e.campaign_id)))
     JOIN public.t_dataset ds ON ((e.exp_id = ds.exp_id)))
  GROUP BY c.campaign, e.experiment, e.reason, e.created;


ALTER TABLE public.v_campaign_experiment_tracking OWNER TO d3l243;

--
-- Name: TABLE v_campaign_experiment_tracking; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_campaign_experiment_tracking TO readaccess;

