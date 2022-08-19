--
-- Name: v_dms_get_new_archive_datasets; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_get_new_archive_datasets AS
 SELECT da.dataset_id,
    ds.dataset
   FROM (public.t_dataset_archive da
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
  WHERE (da.archive_state_id = 1);


ALTER TABLE cap.v_dms_get_new_archive_datasets OWNER TO d3l243;

--
-- Name: TABLE v_dms_get_new_archive_datasets; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dms_get_new_archive_datasets TO readaccess;
GRANT SELECT ON TABLE cap.v_dms_get_new_archive_datasets TO writeaccess;

