--
-- Name: v_instrument_allowed_dataset_type; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_allowed_dataset_type AS
 SELECT gt.dataset_type,
    cachedusage.dataset_usage_count,
    cachedusage.dataset_usage_last_year,
    dtn.description AS type_description,
    gt.comment AS usage_for_this_instrument,
    instname.instrument
   FROM (((public.t_instrument_group_allowed_ds_type gt
     JOIN public.t_dataset_type_name dtn ON ((gt.dataset_type OPERATOR(public.=) dtn.dataset_type)))
     JOIN public.t_instrument_name instname ON ((gt.instrument_group OPERATOR(public.=) instname.instrument_group)))
     LEFT JOIN public.t_cached_instrument_dataset_type_usage cachedusage ON (((instname.instrument_id = cachedusage.instrument_id) AND (dtn.dataset_type OPERATOR(public.=) cachedusage.dataset_type))));


ALTER TABLE public.v_instrument_allowed_dataset_type OWNER TO d3l243;

--
-- Name: TABLE v_instrument_allowed_dataset_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_allowed_dataset_type TO readaccess;

