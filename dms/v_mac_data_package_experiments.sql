--
-- Name: v_mac_data_package_experiments; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mac_data_package_experiments AS
 SELECT v_data_package_experiments_export.data_package_id,
    v_data_package_experiments_export.experiment_id,
    v_data_package_experiments_export.experiment,
    v_data_package_experiments_export.created,
    v_data_package_experiments_export.item_added,
    v_data_package_experiments_export.package_comment
   FROM dpkg.v_data_package_experiments_export;


ALTER TABLE public.v_mac_data_package_experiments OWNER TO d3l243;

--
-- Name: TABLE v_mac_data_package_experiments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mac_data_package_experiments TO readaccess;
GRANT SELECT ON TABLE public.v_mac_data_package_experiments TO writeaccess;

