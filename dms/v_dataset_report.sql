--
-- Name: v_dataset_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_report AS
 SELECT ds.dataset,
    ds.dataset_id AS id,
    dsn.dataset_state AS state,
    dsr.dataset_rating AS rating,
    instname.instrument,
    ds.created,
    ds.comment,
    ds.date_sort_key AS acq_start,
    ds.acq_length_minutes AS acq_length,
    ds.operator_prn AS oper,
    dtn.dataset_type AS type,
    e.experiment,
    c.campaign,
    rrh.request_id AS request,
    rrh.batch_id AS batch,
    COALESCE((((spath.vol_name_client)::text || (spath.storage_path)::text) || (COALESCE(ds.folder_name, ds.dataset))::text), ''::text) AS dataset_folder_path,
    COALESCE((((dap.archive_path)::text || '\'::text) || (COALESCE(ds.folder_name, ds.dataset))::text), ''::text) AS archive_folder_path
   FROM (((((((((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name dsr ON ((ds.dataset_rating_id = dsr.dataset_rating_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     LEFT JOIN public.t_requested_run rrh ON ((ds.dataset_id = rrh.dataset_id)))
     LEFT JOIN public.v_dataset_archive_path dap ON ((ds.dataset_id = dap.dataset_id)));


ALTER TABLE public.v_dataset_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_report TO readaccess;

