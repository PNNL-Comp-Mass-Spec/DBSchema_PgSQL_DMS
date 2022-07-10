--
-- Name: v_dataset_check_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_check_report AS
 SELECT ds.dataset_id,
    ds.dataset,
    ds.created,
    dsn.dataset_state AS state,
    ds.last_affected,
    spath.machine_name AS storage,
    instname.instrument
   FROM (((public.t_dataset ds
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
  WHERE (ds.created >= (CURRENT_TIMESTAMP - '120 days'::interval));


ALTER TABLE public.v_dataset_check_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_check_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_check_report TO readaccess;

