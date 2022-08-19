--
-- Name: v_dms_get_new_datasets; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_get_new_datasets AS
 SELECT ds.dataset,
    ds.dataset_id,
    instname.instrument,
    instname.instrument_class,
    instname.instrument_group
   FROM (public.t_dataset ds
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
  WHERE (ds.dataset_state_id = 1);


ALTER TABLE cap.v_dms_get_new_datasets OWNER TO d3l243;

--
-- Name: TABLE v_dms_get_new_datasets; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dms_get_new_datasets TO readaccess;
GRANT SELECT ON TABLE cap.v_dms_get_new_datasets TO writeaccess;

