--
-- Name: v_eus_export_data_package_jobs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_export_data_package_jobs AS
 SELECT d.dataset_id,
    d.dataset,
    inst.instrument,
    dtn.dataset_type,
    dsn.dataset_state,
    drn.dataset_rating,
    e.experiment,
    o.organism,
    j.job AS analysis_job,
    tool.analysis_tool,
    tool.result_type AS analysis_result_type,
    j.protein_collection_list,
    dp.data_pkg_id AS data_package_id,
    dp.package_name AS data_package_name,
    public.combine_paths('\\aurora.emsl.pnl.gov\archive\prismarch\DataPkgs'::text, dpp.storage_path_relative) AS data_package_path_aurora
   FROM (((((((((((public.t_dataset d
     JOIN public.t_instrument_name inst ON ((d.instrument_id = inst.instrument_id)))
     JOIN public.t_dataset_type_name dtn ON ((d.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_dataset_state_name dsn ON ((d.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_dataset_rating_name drn ON ((d.dataset_rating_id = drn.dataset_rating_id)))
     JOIN public.t_experiments e ON ((d.exp_id = e.exp_id)))
     JOIN public.t_organisms o ON ((e.organism_id = o.organism_id)))
     JOIN public.t_analysis_job j ON ((d.dataset_id = j.dataset_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     LEFT JOIN dpkg.t_data_package_analysis_jobs dpj ON ((j.job = dpj.job)))
     JOIN dpkg.t_data_package dp ON ((dp.data_pkg_id = dpj.data_pkg_id)))
     JOIN dpkg.v_data_package_paths dpp ON ((dp.data_pkg_id = dpp.data_pkg_id)))
  WHERE (j.job_state_id = 4);


ALTER VIEW public.v_eus_export_data_package_jobs OWNER TO d3l243;

--
-- Name: TABLE v_eus_export_data_package_jobs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_export_data_package_jobs TO readaccess;
GRANT SELECT ON TABLE public.v_eus_export_data_package_jobs TO writeaccess;

