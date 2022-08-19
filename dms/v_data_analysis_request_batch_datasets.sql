--
-- Name: v_data_analysis_request_batch_datasets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_analysis_request_batch_datasets AS
 SELECT r.request_id,
    ds.dataset_id,
    ds.dataset,
    e.experiment,
    instname.instrument,
    dfp.dataset_folder_path,
    ds.acq_time_start AS acq_start,
    batchids.batch_id,
    r.campaign,
    r.organism,
    r.request_name,
    r.analysis_type
   FROM (((((public.t_dataset ds
     JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_cached_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     RIGHT JOIN (public.t_data_analysis_request r
     JOIN public.t_data_analysis_request_batch_ids batchids ON ((r.request_id = batchids.request_id))) ON ((rr.batch_id = batchids.batch_id)));


ALTER TABLE public.v_data_analysis_request_batch_datasets OWNER TO d3l243;

--
-- Name: TABLE v_data_analysis_request_batch_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_analysis_request_batch_datasets TO readaccess;
GRANT SELECT ON TABLE public.v_data_analysis_request_batch_datasets TO writeaccess;

