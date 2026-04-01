--
-- Name: t_dataset_nom_stats; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_nom_stats (
    dataset_id integer NOT NULL,
    mz_ion_count integer,
    mz_median real,
    mz_skew real,
    mz_kurtosis real,
    organic_count integer,
    organic_intensity_sum real,
    inorganic_count integer,
    inorganic_intensity_sum real,
    organic_to_inorganic_count_ratio real,
    organic_to_inorganic_intensity_ratio real,
    c13_pair_count integer,
    c13_pair_intensity_sum real,
    cl37_pair_count integer,
    cl37_pair_intensity_sum real,
    c13_to_cl37_pair_ratio real,
    c13_to_cl37_pair_intensity_ratio real,
    chloride_cluster_count integer,
    chloride_cluster_max_length integer,
    chloride_cluster_mean_length real,
    chloride_cluster_peak_count integer,
    chloride_cluster_peak_percent real,
    chloride_cluster_intensity_sum real,
    chloride_cluster_intensity_percent real,
    last_affected timestamp without time zone NOT NULL,
    nom_annotation_job integer,
    calibration_points integer,
    calibration_raw_error_median real,
    calibration_raw_error_stdev real,
    calibration_rms real,
    total_features integer,
    annotated_features integer,
    percent_features_annotated real,
    total_intensity real,
    annotated_intensity real,
    percent_intensity_annotated real,
    assigned_mz_error_rms_ppm real,
    signed_mean_ppm_error real,
    mean_ppm_error real,
    median_ppm_error real,
    weighted_oc real,
    weighted_hc real,
    weighted_nosc real,
    weighted_aimod real,
    descriptor_feature_count integer,
    descriptor_intensity_fraction_percent real
);


ALTER TABLE public.t_dataset_nom_stats OWNER TO d3l243;

--
-- Name: t_dataset_nom_stats pk_t_dataset_nom_stats; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_nom_stats
    ADD CONSTRAINT pk_t_dataset_nom_stats PRIMARY KEY (dataset_id);

ALTER TABLE public.t_dataset_nom_stats CLUSTER ON pk_t_dataset_nom_stats;

--
-- Name: t_dataset_nom_stats fk_t_dataset_nom_stats_t_dataset; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_nom_stats
    ADD CONSTRAINT fk_t_dataset_nom_stats_t_dataset FOREIGN KEY (dataset_id) REFERENCES public.t_dataset(dataset_id);

--
-- Name: TABLE t_dataset_nom_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_nom_stats TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_dataset_nom_stats TO writeaccess;

