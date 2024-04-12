--
-- Name: v_dataset_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_detail_report AS
 SELECT ds.dataset,
    e.experiment,
    instname.instrument,
    ds.created,
    dsn.dataset_state AS state,
    dtn.dataset_type AS type,
    ds.comment,
    ds.operator_username AS operator,
    ds.well,
    ds.separation_type,
    ds.folder_name,
    ((spath.vol_name_client)::text || (spath.storage_path)::text) AS storage,
    instname.instrument_class AS inst_class
   FROM (((((public.t_dataset ds
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)));


ALTER VIEW public.v_dataset_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_detail_report TO writeaccess;

