--
-- Name: v_dataset_nom_stats_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_nom_stats_export AS
 SELECT instname.instrument_group,
    instname.instrument,
    ds.acq_time_start,
    nomstats.dataset_id,
    ds.dataset,
    drn.dataset_rating,
    ds.dataset_rating_id,
    ds.separation_type,
    nomstats.mz_ion_count,
    nomstats.mz_median,
    nomstats.mz_skew,
    nomstats.mz_kurtosis,
    nomstats.organic_count,
    nomstats.organic_intensity_sum,
    nomstats.inorganic_count,
    nomstats.inorganic_intensity_sum,
    nomstats.organic_to_inorganic_count_ratio,
    nomstats.organic_to_inorganic_intensity_ratio,
    nomstats.c13_pair_count,
    nomstats.c13_pair_intensity_sum,
    nomstats.cl37_pair_count,
    nomstats.cl37_pair_intensity_sum,
    nomstats.c13_to_cl37_pair_ratio,
    nomstats.c13_to_cl37_pair_intensity_ratio,
    nomstats.chloride_cluster_count,
    nomstats.chloride_cluster_max_length,
    nomstats.chloride_cluster_mean_length,
    nomstats.chloride_cluster_peak_count,
    nomstats.chloride_cluster_peak_percent,
    nomstats.chloride_cluster_intensity_sum,
    nomstats.chloride_cluster_intensity_percent,
    nomstats.last_affected AS nom_stats_last_affected,
    nomstats.nom_annotation_job,
    nomstats.calibration_points,
    nomstats.calibration_raw_error_median,
    nomstats.calibration_raw_error_stdev,
    nomstats.calibration_rms,
    nomstats.total_features,
    nomstats.annotated_features,
    nomstats.percent_features_annotated,
    nomstats.total_intensity,
    nomstats.annotated_intensity,
    nomstats.percent_intensity_annotated,
    nomstats.assigned_mz_error_rms_ppm,
    nomstats.signed_mean_ppm_error,
    nomstats.mean_ppm_error,
    nomstats.median_ppm_error,
    nomstats.weighted_oc,
    nomstats.weighted_hc,
    nomstats.weighted_nosc,
    nomstats.weighted_aimod,
    nomstats.descriptor_feature_count,
    nomstats.descriptor_intensity_fraction_percent
   FROM (((public.t_dataset_nom_stats nomstats
     JOIN public.t_dataset ds ON ((nomstats.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name drn ON ((ds.dataset_rating_id = drn.dataset_rating_id)));


ALTER VIEW public.v_dataset_nom_stats_export OWNER TO d3l243;

--
-- Name: TABLE v_dataset_nom_stats_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_nom_stats_export TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_nom_stats_export TO writeaccess;

