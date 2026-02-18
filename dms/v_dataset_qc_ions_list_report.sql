--
-- Name: v_dataset_qc_ions_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_qc_ions_list_report AS
 SELECT dqi.dataset_id,
    ds.dataset,
    dqi.mz,
    dqi.max_intensity,
    dqi.median_intensity,
    e.experiment,
    c.campaign,
    instname.instrument,
    ds.created,
    ds.comment,
    dsn.dataset_state AS state,
    ds.acq_length_minutes AS acq_length,
    ds.date_sort_key AS acq_start,
    dtn.dataset_type,
    dl.qc_link
   FROM (((((((public.t_dataset_qc_ions dqi
     JOIN public.t_dataset ds ON ((dqi.dataset_id = ds.dataset_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     LEFT JOIN public.t_cached_dataset_links dl ON ((ds.dataset_id = dl.dataset_id)));


ALTER VIEW public.v_dataset_qc_ions_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_qc_ions_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_qc_ions_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_qc_ions_list_report TO writeaccess;

