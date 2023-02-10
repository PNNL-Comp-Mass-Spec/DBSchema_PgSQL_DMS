--
-- Name: v_experiment_dataset_tracking; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_dataset_tracking AS
 SELECT ds.dataset,
    count(j.job) AS jobs,
    instname.instrument,
    c.campaign,
    ds.created,
    e.experiment AS "#experiment_num"
   FROM ((((public.t_experiments e
     JOIN public.t_dataset ds ON ((e.exp_id = ds.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     LEFT JOIN public.t_analysis_job j ON ((ds.dataset_id = j.dataset_id)))
  GROUP BY ds.dataset, c.campaign, e.experiment, instname.instrument, ds.created;


ALTER TABLE public.v_experiment_dataset_tracking OWNER TO d3l243;

--
-- Name: TABLE v_experiment_dataset_tracking; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_dataset_tracking TO readaccess;

