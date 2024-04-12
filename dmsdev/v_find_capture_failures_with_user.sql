--
-- Name: v_find_capture_failures_with_user; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_find_capture_failures_with_user AS
 SELECT ds.dataset_id,
    ds.dataset AS dataset_name,
    u.name AS operator_name,
    instname.instrument AS inst_name,
    ilr.assigned_source AS xfer_folder
   FROM ((((public.t_dataset ds
     JOIN public.t_users u ON ((ds.operator_username OPERATOR(public.=) u.username)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.v_instrument_list_report ilr ON ((ds.instrument_id = ilr.id)))
  WHERE (ds.dataset_state_id = 5);


ALTER VIEW public.v_find_capture_failures_with_user OWNER TO d3l243;

--
-- Name: TABLE v_find_capture_failures_with_user; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_find_capture_failures_with_user TO readaccess;
GRANT SELECT ON TABLE public.v_find_capture_failures_with_user TO writeaccess;

