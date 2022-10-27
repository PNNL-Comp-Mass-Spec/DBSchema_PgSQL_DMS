--
-- Name: v_dataset; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset AS
 SELECT ds.dataset_id,
    ds.dataset,
    ds.comment,
    ds.created,
    ds.dataset_state_id,
    dsn.dataset_state AS state,
    ds.dataset_rating_id,
    dsrating.dataset_rating AS rating,
    ds.last_affected,
    ds.instrument_id,
    instname.instrument,
    ds.operator_prn,
    ds.dataset_type_id,
    dtn.dataset_type,
    ds.separation_type,
    ds.folder_name,
    ds.storage_path_id,
    dfp.dataset_folder_path,
    ((dfp.dataset_url)::text || 'QC/index.html'::text) AS qc_link,
    ds.exp_id,
    exp.experiment,
    c.campaign,
    ds.internal_standard_id,
    ds.acq_time_start,
    ds.acq_time_end,
    ds.acq_length_minutes,
    ds.lc_column_id,
    ds.scan_count,
    ds.file_size_bytes,
    ds.file_info_last_modified,
    ds.date_sort_key AS "#date_sort_key"
   FROM (((((((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_experiments exp ON ((ds.exp_id = exp.exp_id)))
     JOIN public.t_campaign c ON ((exp.campaign_id = c.campaign_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)));


ALTER TABLE public.v_dataset OWNER TO d3l243;

--
-- Name: TABLE v_dataset; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset TO readaccess;
GRANT SELECT ON TABLE public.v_dataset TO writeaccess;

