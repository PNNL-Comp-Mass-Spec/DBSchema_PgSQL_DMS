--
-- Name: v_mac_data_package_experiments; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mac_data_package_experiments AS
 SELECT dpe.data_pkg_id,
    dpe.experiment_id,
    dpe.experiment,
    dpe.created,
    dpe.item_added,
    dpe.package_comment,
    dpe.data_pkg_id AS data_package_id
   FROM dpkg.v_data_package_experiments_export dpe;


ALTER VIEW public.v_mac_data_package_experiments OWNER TO d3l243;

--
-- Name: TABLE v_mac_data_package_experiments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mac_data_package_experiments TO readaccess;
GRANT SELECT ON TABLE public.v_mac_data_package_experiments TO writeaccess;

