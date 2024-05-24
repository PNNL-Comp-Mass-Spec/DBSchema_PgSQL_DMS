--
-- Name: v_data_package_datasets_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_package_datasets_export AS
 SELECT data_pkg_id,
    dataset_id,
    dataset,
    experiment,
    instrument,
    created,
    item_added,
    package_comment,
    data_package_id
   FROM dpkg.v_data_package_dataset_export;


ALTER VIEW public.v_data_package_datasets_export OWNER TO d3l243;

--
-- Name: VIEW v_data_package_datasets_export; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_data_package_datasets_export IS 'This view is used by ad-hoc query "data_package_datasets", defined at https://dmsdev.pnl.gov/config_db/edit_table/ad_hoc_query.db/utility_queries';

--
-- Name: TABLE v_data_package_datasets_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_package_datasets_export TO readaccess;
GRANT SELECT ON TABLE public.v_data_package_datasets_export TO writeaccess;

