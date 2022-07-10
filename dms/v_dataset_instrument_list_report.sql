--
-- Name: v_dataset_instrument_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_instrument_list_report AS
 SELECT instname.instrument,
    ds.dataset,
    ds.dataset_id AS id,
    ds.created,
    rr.request_id AS request,
    rr.requester_prn AS requester,
    e.experiment,
    e.researcher_prn AS researcher,
    c.campaign,
    instname.instrument_id
   FROM ((((public.t_dataset ds
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)));


ALTER TABLE public.v_dataset_instrument_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_instrument_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_instrument_list_report TO readaccess;

