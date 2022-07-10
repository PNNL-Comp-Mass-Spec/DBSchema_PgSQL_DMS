--
-- Name: v_data_helper_dataset_lookup; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_helper_dataset_lookup AS
 SELECT da.dataset_id AS id,
    ds.dataset AS name,
    dasn.archive_state AS state,
    apath.archive_path,
    da.instrument_data_purged AS is_purged
   FROM (((public.t_dataset_archive da
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
     JOIN public.t_archive_path apath ON ((da.storage_path_id = apath.archive_path_id)));


ALTER TABLE public.v_data_helper_dataset_lookup OWNER TO d3l243;

--
-- Name: TABLE v_data_helper_dataset_lookup; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_helper_dataset_lookup TO readaccess;

