--
-- Name: v_dms_dataset_archive_status; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_dataset_archive_status AS
 SELECT da.dataset_id,
    ds.dataset,
    ds.dataset_state_id,
    da.archive_state_id,
    da.archive_state_last_affected,
    da.archive_date,
    da.last_update,
    da.archive_update_state_id,
    da.archive_update_state_last_affected,
    da.last_successful_archive
   FROM (public.t_dataset_archive da
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)));


ALTER VIEW cap.v_dms_dataset_archive_status OWNER TO d3l243;

--
-- Name: TABLE v_dms_dataset_archive_status; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dms_dataset_archive_status TO readaccess;
GRANT SELECT ON TABLE cap.v_dms_dataset_archive_status TO writeaccess;

