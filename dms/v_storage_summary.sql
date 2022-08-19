--
-- Name: v_storage_summary; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_summary AS
 SELECT slp.vol_client,
    slp.storage_path,
    slp.vol_server,
    instgroup.instrument_group AS inst_group,
    instname.instrument,
    slp.datasets,
    COALESCE(sum((((((ds.file_size_bytes)::numeric / 1024.0) / 1024.0) / 1024.0))::numeric(9,2)), (0)::numeric) AS file_size_gb,
    max(ds.created) AS created_max
   FROM (((public.t_instrument_name instname
     JOIN public.t_instrument_group instgroup ON ((instname.instrument_group OPERATOR(public.=) instgroup.instrument_group)))
     JOIN public.v_storage_list_report slp ON ((instname.instrument OPERATOR(public.=) slp.instrument)))
     JOIN public.t_dataset ds ON ((slp.id = ds.storage_path_id)))
  WHERE ((slp.storage_path_function OPERATOR(public.<>) 'inbox'::public.citext) AND (slp.datasets > 0))
  GROUP BY slp.vol_client, slp.storage_path, slp.vol_server, instgroup.instrument_group, instname.instrument, slp.datasets;


ALTER TABLE public.v_storage_summary OWNER TO d3l243;

--
-- Name: TABLE v_storage_summary; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_summary TO readaccess;
GRANT SELECT ON TABLE public.v_storage_summary TO writeaccess;

