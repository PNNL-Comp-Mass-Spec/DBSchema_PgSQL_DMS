--
-- Name: v_archive_check_update_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_check_update_report AS
 SELECT da.dataset_id,
    ds.dataset,
    sp.machine_name AS storage_server,
    ausn.archive_update_state,
    da.archive_update_state_last_affected AS update_last_affected,
    dasn.archive_state,
    da.archive_state_last_affected AS last_affected,
    instname.instrument,
    ap.archive_path,
    ap.archive_server_name AS archive_server,
    ds.created AS ds_created,
    da.last_update
   FROM ((((((public.t_dataset_archive da
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
     JOIN public.t_archive_path ap ON ((da.storage_path_id = ap.archive_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_archive_update_state_name ausn ON ((da.archive_update_state_id = ausn.archive_update_state_id)))
     JOIN public.t_storage_path sp ON ((ds.storage_path_id = sp.storage_path_id)))
  WHERE (NOT (da.archive_update_state_id = ANY (ARRAY[4, 6])));


ALTER TABLE public.v_archive_check_update_report OWNER TO d3l243;

--
-- Name: TABLE v_archive_check_update_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_check_update_report TO readaccess;
GRANT SELECT ON TABLE public.v_archive_check_update_report TO writeaccess;

