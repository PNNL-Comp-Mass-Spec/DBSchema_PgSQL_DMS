--
-- Name: v_archive_check_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_check_report AS
 SELECT ds.dataset_id,
    ds.dataset,
    dasn.archive_state,
    da.archive_state_last_affected AS last_affected,
    instname.instrument,
    spath.machine_name AS storage_server,
    archpath.archive_path,
    da.archive_processor,
    da.update_processor,
    da.verification_processor
   FROM (((((public.t_dataset_archive da
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
     JOIN public.t_archive_path archpath ON ((da.storage_path_id = archpath.archive_path_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
  WHERE (da.archive_state_id <> ALL (ARRAY[3, 4, 9, 10, 14, 15]));


ALTER TABLE public.v_archive_check_report OWNER TO d3l243;

--
-- Name: TABLE v_archive_check_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_check_report TO readaccess;
GRANT SELECT ON TABLE public.v_archive_check_report TO writeaccess;

