--
-- Name: v_dataset_list_campaign; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_list_campaign AS
 SELECT ds.dataset,
    dsn.dataset_state AS state,
    dsrating.dataset_rating AS rating,
    instname.instrument_class AS class,
    c.campaign,
    ds.dataset_id AS id
   FROM (((((public.t_dataset ds
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)));


ALTER VIEW public.v_dataset_list_campaign OWNER TO d3l243;

--
-- Name: TABLE v_dataset_list_campaign; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_list_campaign TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_list_campaign TO writeaccess;

