--
-- Name: v_dataset_nom_stats_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_nom_stats_detail_report AS
 SELECT instname.instrument_group,
    instname.instrument,
    ds.acq_time_start,
    nomstats.dataset_id,
    ds.dataset,
    drn.dataset_rating,
    ds.dataset_rating_id,
    ('nom_stats/instrument/'::text || (instname.instrument)::text) AS nom_stats,
    nomstats.mz_ion_count,
    public.number_to_string((nomstats.mz_median)::double precision, 3) AS mz_median,
    public.number_to_string((nomstats.mz_skew)::double precision, 3) AS mz_skew,
    public.number_to_string((nomstats.mz_kurtosis)::double precision, 3) AS mz_kurtosis,
    nomstats.organic_count,
    public.number_to_string((nomstats.organic_intensity_sum)::double precision, 3) AS organic_intensity_sum,
    nomstats.inorganic_count,
    public.number_to_string((nomstats.inorganic_intensity_sum)::double precision, 3) AS inorganic_intensity_sum,
    public.number_to_string((nomstats.organic_to_inorganic_count_ratio)::double precision, 3) AS organic_to_inorganic_count_ratio,
    public.number_to_string((nomstats.organic_to_inorganic_intensity_ratio)::double precision, 3) AS organic_to_inorganic_intensity_ratio,
    nomstats.c13_pair_count,
    public.number_to_string((nomstats.c13_pair_intensity_sum)::double precision, 3) AS c13_pair_intensity_sum,
    nomstats.cl37_pair_count,
    public.number_to_string((nomstats.cl37_pair_intensity_sum)::double precision, 3) AS cl37_pair_intensity_sum,
    public.number_to_string((nomstats.c13_to_cl37_pair_ratio)::double precision, 3) AS c13_to_cl37_pair_ratio,
    public.number_to_string((nomstats.c13_to_cl37_pair_intensity_ratio)::double precision, 3) AS c13_to_cl37_pair_intensity_ratio,
    nomstats.chloride_cluster_count,
    nomstats.chloride_cluster_max_length,
    public.number_to_string((nomstats.chloride_cluster_mean_length)::double precision, 3) AS chloride_cluster_mean_length,
    nomstats.chloride_cluster_peak_count,
    public.number_to_string((nomstats.chloride_cluster_peak_percent)::double precision, 3) AS chloride_cluster_peak_percent,
    public.number_to_string((nomstats.chloride_cluster_intensity_sum)::double precision, 3) AS chloride_cluster_intensity_sum,
    public.number_to_string((nomstats.chloride_cluster_intensity_percent)::double precision, 3) AS chloride_cluster_intensity_percent,
    nomstats.last_affected AS nom_stats_last_affected,
    nomstats.nom_annotation_job,
    nomstats.calibration_points,
    public.number_to_string((nomstats.calibration_raw_error_median)::double precision, 3) AS calibration_raw_error_median,
    public.number_to_string((nomstats.calibration_raw_error_stdev)::double precision, 3) AS calibration_raw_error_stdev,
    public.number_to_string((nomstats.calibration_rms)::double precision, 3) AS calibration_rms,
    nomstats.total_features,
    nomstats.annotated_features,
    public.number_to_string((nomstats.percent_features_annotated)::double precision, 3) AS percent_features_annotated,
    public.number_to_string((nomstats.total_intensity)::double precision, 3) AS total_intensity,
    public.number_to_string((nomstats.annotated_intensity)::double precision, 3) AS annotated_intensity,
    public.number_to_string((nomstats.percent_intensity_annotated)::double precision, 3) AS percent_intensity_annotated,
    public.number_to_string((nomstats.assigned_mz_error_rms_ppm)::double precision, 3) AS assigned_mz_error_rms_ppm,
    public.number_to_string((nomstats.signed_mean_ppm_error)::double precision, 3) AS signed_mean_ppm_error,
    public.number_to_string((nomstats.mean_ppm_error)::double precision, 3) AS mean_ppm_error,
    public.number_to_string((nomstats.median_ppm_error)::double precision, 3) AS median_ppm_error,
    public.number_to_string((nomstats.weighted_oc)::double precision, 3) AS weighted_oc,
    public.number_to_string((nomstats.weighted_hc)::double precision, 3) AS weighted_hc,
    public.number_to_string((nomstats.weighted_nosc)::double precision, 3) AS weighted_nosc,
    public.number_to_string((nomstats.weighted_aimod)::double precision, 3) AS weighted_aimod,
    nomstats.descriptor_feature_count,
    public.number_to_string((nomstats.descriptor_intensity_fraction_percent)::double precision, 3) AS descriptor_intensity_fraction_percent
   FROM (((public.t_dataset_nom_stats nomstats
     JOIN public.t_dataset ds ON ((nomstats.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name drn ON ((ds.dataset_rating_id = drn.dataset_rating_id)));


ALTER VIEW public.v_dataset_nom_stats_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_nom_stats_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_nom_stats_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_nom_stats_detail_report TO writeaccess;

