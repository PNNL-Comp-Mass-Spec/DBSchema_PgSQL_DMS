--
-- Name: v_campaign_tracking; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_campaign_tracking AS
 SELECT c.campaign,
    ct.biomaterial_count AS cell_cultures,
    ct.experiment_count AS experiments,
    ct.dataset_count AS datasets,
    ct.job_count AS jobs,
    c.comment,
    c.created
   FROM (public.t_campaign_tracking ct
     JOIN public.t_campaign c ON ((ct.campaign_id = c.campaign_id)));


ALTER TABLE public.v_campaign_tracking OWNER TO d3l243;

--
-- Name: TABLE v_campaign_tracking; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_campaign_tracking TO readaccess;

