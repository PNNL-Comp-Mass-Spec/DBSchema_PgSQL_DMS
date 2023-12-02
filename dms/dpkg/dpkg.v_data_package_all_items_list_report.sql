--
-- Name: v_data_package_all_items_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_all_items_list_report AS
 SELECT dpj.data_pkg_id AS id,
    (((('<item pkg="'::text || (dpj.data_pkg_id)::text) || '" type="Job" id="'::text) || (dpj.job)::text) || '"/>'::text) AS sel,
    'Job'::text AS item_type,
    (dpj.job)::text AS item,
    ds.dataset AS parent_entity,
    t.analysis_tool AS info,
    dpj.item_added,
    dpj.package_comment,
    1 AS sort_key
   FROM (((dpkg.t_data_package_analysis_jobs dpj
     JOIN public.t_analysis_job aj ON ((dpj.job = aj.job)))
     JOIN public.t_analysis_tool t ON ((aj.analysis_tool_id = t.analysis_tool_id)))
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
UNION
 SELECT dpd.data_pkg_id AS id,
    (((('<item pkg="'::text || (dpd.data_pkg_id)::text) || '" type="Dataset" id="'::text) || (ds.dataset)::text) || '"/>'::text) AS sel,
    'Dataset'::text AS item_type,
    ds.dataset AS item,
    e.experiment AS parent_entity,
    instname.instrument AS info,
    dpd.item_added,
    dpd.package_comment,
    2 AS sort_key
   FROM (((dpkg.t_data_package_datasets dpd
     JOIN public.t_dataset ds ON ((dpd.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
UNION
 SELECT dpe.data_pkg_id AS id,
    (((('<item pkg="'::text || (dpe.data_pkg_id)::text) || '" type="Experiment" id="'::text) || (e.experiment)::text) || '"/>'::text) AS sel,
    'Experiment'::text AS item_type,
    e.experiment AS item,
    ''::public.citext AS parent_entity,
    ''::public.citext AS info,
    dpe.item_added,
    dpe.package_comment,
    3 AS sort_key
   FROM (dpkg.t_data_package_experiments dpe
     JOIN public.t_experiments e ON ((e.exp_id = dpe.experiment_id)))
UNION
 SELECT dpb.data_pkg_id AS id,
    (((('<item pkg="'::text || (dpb.data_pkg_id)::text) || '" type="Biomaterial" id="'::text) || (b.biomaterial_name)::text) || '"/>'::text) AS sel,
    'Biomaterial'::text AS item_type,
    b.biomaterial_name AS item,
    c.campaign AS parent_entity,
    btn.biomaterial_type AS info,
    dpb.item_added,
    dpb.package_comment,
    4 AS sort_key
   FROM (((((dpkg.t_data_package_biomaterial dpb
     JOIN public.t_biomaterial b ON ((dpb.biomaterial_id = b.biomaterial_id)))
     JOIN public.t_biomaterial_type_name btn ON ((b.biomaterial_type_id = btn.biomaterial_type_id)))
     JOIN public.t_campaign c ON ((b.campaign_id = c.campaign_id)))
     JOIN public.t_material_containers mc ON ((b.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)));


ALTER VIEW dpkg.v_data_package_all_items_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_all_items_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_all_items_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_all_items_list_report TO writeaccess;

