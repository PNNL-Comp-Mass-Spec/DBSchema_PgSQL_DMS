--
-- Name: v_dataset_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_metadata AS
 SELECT ds.dataset AS name,
    ds.dataset_id AS id,
    e.experiment,
    instname.instrument,
    instname.instrument_class AS instrument_description,
    ds.separation_type,
    lc.lc_column,
    ds.wellplate,
    ds.well,
    dtn.dataset_type AS type,
    u.name_with_username AS operator,
    ds.comment,
    dsrating.dataset_rating AS rating,
    rr.request_id AS request,
    dsn.dataset_state AS state,
    dasn.archive_state,
    ds.created,
    ds.folder_name,
    ds.acq_time_start AS acquisition_start,
    ds.acq_time_end AS acquisition_end,
    ds.scan_count,
    ((((ds.file_size_bytes)::numeric / 1024.0) / 1024.0))::integer AS file_size_mb
   FROM ((((((((((public.t_dataset ds
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_users u ON ((ds.operator_username OPERATOR(public.=) u.username)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_dataset_archive da ON ((da.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_dataset_archive_state_name dasn ON ((dasn.archive_state_id = da.archive_state_id)));


ALTER VIEW public.v_dataset_metadata OWNER TO d3l243;

--
-- Name: TABLE v_dataset_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_metadata TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_metadata TO writeaccess;

