--
-- Name: v_mage_data_package_analysis_jobs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_data_package_analysis_jobs AS
 SELECT vma.job,
    vma.state,
    vma.dataset,
    vma.dataset_id,
    vma.tool,
    vma.parameter_file,
    vma.settings_file,
    vma.instrument,
    vma.experiment,
    vma.campaign,
    vma.organism,
    vma.organism_db,
    vma.protein_collection_list,
    vma.protein_options,
    vma.comment,
    vma.results_folder,
    vma.folder,
    dpj.data_pkg_id,
    dpj.package_comment,
    instname.instrument_class,
    dtn.dataset_type,
    dpj.data_pkg_id AS data_package_id
   FROM ((((public.v_mage_analysis_jobs vma
     JOIN dpkg.v_data_package_analysis_jobs_export dpj ON ((vma.job = dpj.job)))
     JOIN public.t_dataset ds ON ((vma.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)));


ALTER VIEW public.v_mage_data_package_analysis_jobs OWNER TO d3l243;

--
-- Name: TABLE v_mage_data_package_analysis_jobs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_data_package_analysis_jobs TO readaccess;
GRANT SELECT ON TABLE public.v_mage_data_package_analysis_jobs TO writeaccess;

