--
-- Name: v_find_dataset; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_find_dataset AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    e.experiment,
    c.campaign,
    dsn.dataset_state AS state,
    instname.instrument,
    ds.created,
    ds.comment,
    dsrating.dataset_rating AS rating,
    dtn.dataset_type AS type,
    ds.operator_username AS operator,
    dfp.dataset_folder_path,
    dfp.archive_folder_path,
    COALESCE(ds.acq_time_start, rrh.request_run_start) AS acq_start,
    ds.acq_length_minutes AS acq_length,
    ds.scan_count,
    lc.lc_column,
    rrh.blocking_factor,
    rrh.block,
    rrh.run_order
   FROM (((((((((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     LEFT JOIN public.t_requested_run rrh ON ((ds.dataset_id = rrh.dataset_id)));


ALTER TABLE public.v_find_dataset OWNER TO d3l243;

--
-- Name: TABLE v_find_dataset; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_find_dataset TO readaccess;

