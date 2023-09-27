--
-- Name: v_data_package_dataset_export; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_dataset_export AS
 SELECT dpd.data_pkg_id,
    dpd.dataset_id,
    ds.dataset,
    e.experiment,
    instname.instrument,
    ds.created,
    dpd.item_added,
    dpd.package_comment,
    dpd.data_pkg_id AS data_package_id
   FROM (((dpkg.t_data_package_datasets dpd
     JOIN public.t_dataset ds ON ((dpd.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)));


ALTER TABLE dpkg.v_data_package_dataset_export OWNER TO d3l243;

--
-- Name: TABLE v_data_package_dataset_export; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_dataset_export TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_dataset_export TO writeaccess;

