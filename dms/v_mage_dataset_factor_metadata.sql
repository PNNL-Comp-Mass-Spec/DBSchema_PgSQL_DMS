--
-- Name: v_mage_dataset_factor_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_dataset_factor_metadata AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    exp.experiment,
    c.campaign,
    dsn.dataset_state AS state,
    dsrating.dataset_rating AS rating,
    instname.instrument,
    ds.comment,
    dtn.dataset_type,
    lc.lc_column,
    ds.separation_type,
    rr.request_id AS request,
    COALESCE(ds.acq_time_start, rr.request_run_start) AS acq_start,
    COALESCE(ds.acq_time_end, rr.request_run_finish) AS acq_end,
    ds.acq_length_minutes AS acq_length,
    ds.scan_count,
    ds.created
   FROM ((((((((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_experiments exp ON ((ds.exp_id = exp.exp_id)))
     JOIN public.t_campaign c ON ((exp.campaign_id = c.campaign_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
  WHERE (EXISTS ( SELECT t_factor.factor_id,
            t_factor.type,
            t_factor.target_id,
            t_factor.name,
            t_factor.value
           FROM public.t_factor
          WHERE ((rr.request_id = t_factor.target_id) AND (t_factor.type OPERATOR(public.=) 'Run_Request'::public.citext))));


ALTER TABLE public.v_mage_dataset_factor_metadata OWNER TO d3l243;

--
-- Name: TABLE v_mage_dataset_factor_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_dataset_factor_metadata TO readaccess;
GRANT SELECT ON TABLE public.v_mage_dataset_factor_metadata TO writeaccess;

