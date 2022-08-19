--
-- Name: v_data_package_all_items_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_all_items_list_report AS
 SELECT t_data_package_analysis_jobs.data_pkg_id AS id,
    (((('<item pkg="'::text || (t_data_package_analysis_jobs.data_pkg_id)::text) || '" type="Job" id="'::text) || (t_data_package_analysis_jobs.job)::text) || '"/>'::text) AS sel,
    'Job'::text AS item_type,
    (t_data_package_analysis_jobs.job)::text AS item,
    t_data_package_analysis_jobs.dataset AS parent_entity,
    t_data_package_analysis_jobs.tool AS info,
    t_data_package_analysis_jobs.item_added,
    t_data_package_analysis_jobs.package_comment,
    1 AS sort_key
   FROM dpkg.t_data_package_analysis_jobs
UNION
 SELECT t_data_package_datasets.data_pkg_id AS id,
    (((('<item pkg="'::text || (t_data_package_datasets.data_pkg_id)::text) || '" type="Dataset" id="'::text) || (t_data_package_datasets.dataset)::text) || '"/>'::text) AS sel,
    'Dataset'::text AS item_type,
    t_data_package_datasets.dataset AS item,
    t_data_package_datasets.experiment AS parent_entity,
    t_data_package_datasets.instrument AS info,
    t_data_package_datasets.item_added,
    t_data_package_datasets.package_comment,
    2 AS sort_key
   FROM dpkg.t_data_package_datasets
UNION
 SELECT t_data_package_experiments.data_pkg_id AS id,
    (((('<item pkg="'::text || (t_data_package_experiments.data_pkg_id)::text) || '" type="Experiment" id="'::text) || (t_data_package_experiments.experiment)::text) || '"/>'::text) AS sel,
    'Experiment'::text AS item_type,
    t_data_package_experiments.experiment AS item,
    ''::public.citext AS parent_entity,
    ''::public.citext AS info,
    t_data_package_experiments.item_added,
    t_data_package_experiments.package_comment,
    3 AS sort_key
   FROM dpkg.t_data_package_experiments
UNION
 SELECT t_data_package_biomaterial.data_pkg_id AS id,
    (((('<item pkg="'::text || (t_data_package_biomaterial.data_pkg_id)::text) || '" type="Biomaterial" id="'::text) || (t_data_package_biomaterial.biomaterial)::text) || '"/>'::text) AS sel,
    'Biomaterial'::text AS item_type,
    t_data_package_biomaterial.biomaterial AS item,
    t_data_package_biomaterial.campaign AS parent_entity,
    t_data_package_biomaterial.type AS info,
    t_data_package_biomaterial.item_added,
    t_data_package_biomaterial.package_comment,
    4 AS sort_key
   FROM dpkg.t_data_package_biomaterial;


ALTER TABLE dpkg.v_data_package_all_items_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_all_items_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_all_items_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_all_items_list_report TO writeaccess;

