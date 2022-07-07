--
-- Name: v_archive_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_list_report AS
 SELECT da.dataset_id AS id,
    ds.dataset,
    instname.instrument,
    ds.created,
    dasn.archive_state AS state,
    aus.archive_update_state AS update,
    da.archive_date AS entered,
    da.last_update,
    da.last_verify,
    apath.archive_path,
    apath.archive_server_name AS archive_server,
    da.instrument_data_purged
   FROM (((((public.t_dataset_archive da
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
     JOIN public.t_archive_path apath ON ((da.storage_path_id = apath.archive_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_archive_update_state_name aus ON ((da.archive_update_state_id = aus.archive_update_state_id)));


ALTER TABLE public.v_archive_list_report OWNER TO d3l243;

--
-- Name: TABLE v_archive_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_list_report TO readaccess;

