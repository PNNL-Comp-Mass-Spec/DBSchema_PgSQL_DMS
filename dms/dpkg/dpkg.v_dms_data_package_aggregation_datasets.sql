--
-- Name: v_dms_data_package_aggregation_datasets; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_dms_data_package_aggregation_datasets AS
 SELECT tpd.data_pkg_id,
    ds.dataset_id,
    ds.dataset,
    dfp.dataset_folder_path,
    dfp.archive_folder_path,
    instname.instrument AS instrument_name,
    instname.instrument_group,
    instname.instrument_class,
    instclass.raw_data_type,
    ds.acq_time_start,
    ds.created,
    org.organism,
    org.ncbi_taxonomy_id AS experiment_newt_id,
    newt.term_name AS experiment_newt_name,
    e.experiment,
    e.reason AS experiment_reason,
    e.comment AS experiment_comment,
    tpd.package_comment,
    e.tissue_id AS experiment_tissue_id,
    bto.term_name AS experiment_tissue_name
   FROM ((((((((((dpkg.t_data_package_datasets tpd
     JOIN public.t_dataset ds ON ((tpd.dataset_id = ds.dataset_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((dfp.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_instrument_class instclass ON ((instname.instrument_class OPERATOR(public.=) instclass.instrument_class)))
     JOIN public.t_storage_path sp ON ((ds.storage_path_id = sp.storage_path_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign campaign ON ((e.campaign_id = campaign.campaign_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     LEFT JOIN ont.t_cv_bto_cached_names bto ON ((e.tissue_id OPERATOR(public.=) bto.identifier)))
     LEFT JOIN ont.t_cv_newt newt ON ((org.ncbi_taxonomy_id = newt.identifier)));


ALTER TABLE dpkg.v_dms_data_package_aggregation_datasets OWNER TO d3l243;

--
-- Name: VIEW v_dms_data_package_aggregation_datasets; Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON VIEW dpkg.v_dms_data_package_aggregation_datasets IS 'Note that this view is used by V_DMS_Data_Package_Datasets in DMS_Pipeline, and the PRIDE converter plugin uses that view to retrieve metadata for data package datasets';

