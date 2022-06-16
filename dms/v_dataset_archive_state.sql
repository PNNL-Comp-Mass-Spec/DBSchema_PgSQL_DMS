--
-- Name: v_dataset_archive_state; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_archive_state AS
 SELECT da.dataset,
    dasn.archive_state AS state,
    da.folder_name,
    da.server_vol,
    da.client_vol,
    da.storage_path,
    da.archive_path,
    da.instrument_class,
    da.last_update,
    da.instrument_name
   FROM (public.v_dataset_archive da
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state = dasn.archive_state_id)));


ALTER TABLE public.v_dataset_archive_state OWNER TO d3l243;

--
-- Name: TABLE v_dataset_archive_state; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_archive_state TO readaccess;

