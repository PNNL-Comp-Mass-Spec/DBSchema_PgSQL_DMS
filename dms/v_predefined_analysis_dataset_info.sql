--
-- Name: v_predefined_analysis_dataset_info; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_predefined_analysis_dataset_info AS
 SELECT c.campaign,
    e.experiment,
    e.comment AS experiment_comment,
    e.labelling AS experiment_labelling,
    org.organism,
    instname.instrument,
    instname.instrument_class,
    ds.comment AS dataset_comment,
    ds.dataset_id AS id,
    ds.dataset,
    ds.dataset_rating_id AS rating,
    drn.dataset_rating AS rating_name,
    dstypename.dataset_type,
    septype.separation_type,
    COALESCE(ds.acq_time_start, ds.created) AS ds_date,
    ds.scan_count
   FROM (((((((public.t_dataset ds
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_dataset_type_name dstypename ON ((ds.dataset_type_id = dstypename.dataset_type_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.t_dataset_rating_name drn ON ((ds.dataset_rating_id = drn.dataset_rating_id)))
     LEFT JOIN public.t_secondary_sep septype ON ((ds.separation_type OPERATOR(public.=) septype.separation_type)));


ALTER VIEW public.v_predefined_analysis_dataset_info OWNER TO d3l243;

--
-- Name: TABLE v_predefined_analysis_dataset_info; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_analysis_dataset_info TO readaccess;
GRANT SELECT ON TABLE public.v_predefined_analysis_dataset_info TO writeaccess;

