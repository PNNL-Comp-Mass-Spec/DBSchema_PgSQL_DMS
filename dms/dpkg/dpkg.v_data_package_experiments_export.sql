--
-- Name: v_data_package_experiments_export; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_experiments_export AS
 SELECT dpe.data_pkg_id,
    dpe.experiment_id,
    e.experiment,
    e.created,
    dpe.item_added,
    dpe.package_comment,
    dpe.data_pkg_id AS data_package_id
   FROM (dpkg.t_data_package_experiments dpe
     JOIN public.t_experiments e ON ((e.exp_id = dpe.experiment_id)));


ALTER VIEW dpkg.v_data_package_experiments_export OWNER TO d3l243;

--
-- Name: TABLE v_data_package_experiments_export; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_experiments_export TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_experiments_export TO writeaccess;

