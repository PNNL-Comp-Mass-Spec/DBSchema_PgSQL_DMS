--
-- Name: v_dataset_nom_stats_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_nom_stats_list_report AS
 SELECT instname.instrument_group,
    instname.instrument,
    ds.acq_time_start,
    nomstats.dataset_id,
    ds.dataset,
    drn.dataset_rating,
    ds.dataset_rating_id,
    nomstats.mz_ion_count,
    (nomstats.mz_median)::numeric(9,3) AS mz_median,
    (nomstats.mz_skew)::numeric(9,3) AS mz_skew,
    (nomstats.mz_kurtosis)::numeric(9,3) AS mz_kurtosis,
    (nomstats.assigned_mz_error_rms_ppm)::numeric(9,3) AS mz_error_rms_ppm,
    (nomstats.signed_mean_ppm_error)::numeric(9,3) AS signed_mean_ppm_error,
    nomstats.organic_count,
    (nomstats.organic_intensity_sum)::numeric(19,0) AS organic_intensity_sum,
    nomstats.inorganic_count,
    (nomstats.inorganic_intensity_sum)::numeric(19,0) AS inorganic_intensity_sum,
    (nomstats.organic_to_inorganic_count_ratio)::numeric(9,3) AS organic_to_inorganic_count_ratio,
    (nomstats.organic_to_inorganic_intensity_ratio)::numeric(9,3) AS organic_to_inorganic_intensity_ratio,
    nomstats.c13_pair_count,
    (nomstats.c13_pair_intensity_sum)::numeric(19,0) AS c13_pair_intensity_sum,
    nomstats.cl37_pair_count,
    (nomstats.cl37_pair_intensity_sum)::numeric(19,0) AS cl37_pair_intensity_sum,
    (nomstats.c13_to_cl37_pair_ratio)::numeric(9,3) AS c13_to_cl37_pair_ratio,
    (nomstats.c13_to_cl37_pair_intensity_ratio)::numeric(9,3) AS c13_to_cl37_pair_intensity_ratio,
    nomstats.chloride_cluster_count,
    nomstats.chloride_cluster_max_length,
    (nomstats.chloride_cluster_mean_length)::numeric(9,3) AS chloride_cluster_mean_length,
    nomstats.chloride_cluster_peak_count,
    (nomstats.chloride_cluster_peak_percent)::numeric(9,3) AS chloride_cluster_peak_percent,
    (nomstats.chloride_cluster_intensity_sum)::numeric(19,0) AS chloride_cluster_intensity_sum,
    (nomstats.chloride_cluster_intensity_percent)::numeric(9,3) AS chloride_cluster_intensity_percent,
    nomstats.last_affected AS nom_stats_last_affected,
    nomstats.nom_annotation_job,
    nomstats.calibration_points,
    (nomstats.calibration_raw_error_median)::numeric(9,3) AS calibration_raw_error_median,
    (nomstats.calibration_raw_error_stdev)::numeric(9,3) AS calibration_raw_error_stdev,
    (nomstats.calibration_rms)::numeric(9,3) AS calibration_rms,
    nomstats.total_features,
    nomstats.annotated_features,
    (nomstats.percent_features_annotated)::numeric(9,3) AS percent_features_annotated,
    (nomstats.total_intensity)::numeric(19,3) AS total_intensity,
    (nomstats.annotated_intensity)::numeric(19,3) AS annotated_intensity,
    (nomstats.percent_intensity_annotated)::numeric(9,3) AS percent_intensity_annotated,
    (nomstats.mean_ppm_error)::numeric(9,3) AS mean_ppm_error,
    (nomstats.median_ppm_error)::numeric(9,3) AS median_ppm_error,
    (nomstats.weighted_oc)::numeric(9,3) AS weighted_oc,
    (nomstats.weighted_hc)::numeric(9,3) AS weighted_hc,
    (nomstats.weighted_nosc)::numeric(9,3) AS weighted_nosc,
    (nomstats.weighted_aimod)::numeric(9,3) AS weighted_aimod,
    nomstats.descriptor_feature_count,
    (nomstats.descriptor_intensity_fraction_percent)::numeric(9,3) AS descriptor_intensity_fraction_percent
   FROM (((public.t_dataset_nom_stats nomstats
     JOIN public.t_dataset ds ON ((nomstats.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name drn ON ((ds.dataset_rating_id = drn.dataset_rating_id)));


ALTER VIEW public.v_dataset_nom_stats_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_nom_stats_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_nom_stats_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_nom_stats_list_report TO writeaccess;

