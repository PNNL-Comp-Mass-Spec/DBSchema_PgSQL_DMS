--
-- Name: v_dataset_qc_metrics_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_qc_metrics_export AS
 SELECT instname.instrument_group,
    instname.instrument,
    ds.acq_time_start,
    dqc.dataset_id,
    ds.dataset,
    drn.dataset_rating,
    ds.dataset_rating_id,
    dqc.p_2c,
    dqc.mass_error_ppm,
    dqc.mass_error_ppm_viper,
    dqc.amts_10pct_fdr,
    dqc.amts_25pct_fdr,
    dqc.xic_fwhm_q2,
    dqc.xic_wide_frac,
    dqc.phos_2c,
    dqc.quameter_job,
    dqc.xic_fwhm_q1,
    dqc.xic_fwhm_q3,
    dqc.xic_height_q2,
    dqc.xic_height_q3,
    dqc.xic_height_q4,
    dqc.rt_duration,
    dqc.rt_tic_q1,
    dqc.rt_tic_q2,
    dqc.rt_tic_q3,
    dqc.rt_tic_q4,
    dqc.rt_ms_q1,
    dqc.rt_ms_q2,
    dqc.rt_ms_q3,
    dqc.rt_ms_q4,
    dqc.rt_msms_q1,
    dqc.rt_msms_q2,
    dqc.rt_msms_q3,
    dqc.rt_msms_q4,
    dqc.ms1_tic_change_q2,
    dqc.ms1_tic_change_q3,
    dqc.ms1_tic_change_q4,
    dqc.ms1_tic_q2,
    dqc.ms1_tic_q3,
    dqc.ms1_tic_q4,
    dqc.ms1_count,
    dqc.ms1_freq_max,
    dqc.ms1_density_q1,
    dqc.ms1_density_q2,
    dqc.ms1_density_q3,
    dqc.ms2_count,
    dqc.ms2_freq_max,
    dqc.ms2_density_q1,
    dqc.ms2_density_q2,
    dqc.ms2_density_q3,
    dqc.ms2_prec_z_1,
    dqc.ms2_prec_z_2,
    dqc.ms2_prec_z_3,
    dqc.ms2_prec_z_4,
    dqc.ms2_prec_z_5,
    dqc.ms2_prec_z_more,
    dqc.ms2_prec_z_likely_1,
    dqc.ms2_prec_z_likely_multi,
    dqc.quameter_last_affected,
    dqc.smaqc_job,
    dqc.c_1a,
    dqc.c_1b,
    dqc.c_2a,
    dqc.c_2b,
    dqc.c_3a,
    dqc.c_3b,
    dqc.c_4a,
    dqc.c_4b,
    dqc.c_4c,
    dqc.ds_1a,
    dqc.ds_1b,
    dqc.ds_2a,
    dqc.ds_2b,
    dqc.ds_3a,
    dqc.ds_3b,
    dqc.is_1a,
    dqc.is_1b,
    dqc.is_2,
    dqc.is_3a,
    dqc.is_3b,
    dqc.is_3c,
    dqc.ms1_1,
    dqc.ms1_2a,
    dqc.ms1_2b,
    dqc.ms1_3a,
    dqc.ms1_3b,
    dqc.ms1_5a,
    dqc.ms1_5b,
    dqc.ms1_5c,
    dqc.ms1_5d,
    dqc.ms2_1,
    dqc.ms2_2,
    dqc.ms2_3,
    dqc.ms2_4a,
    dqc.ms2_4b,
    dqc.ms2_4c,
    dqc.ms2_4d,
    dqc.p_1a,
    dqc.p_1b,
    dqc.p_2a,
    dqc.p_2b,
    dqc.p_3,
    dqc.phos_2a,
    dqc.keratin_2a,
    dqc.keratin_2c,
    dqc.p_4a,
    dqc.p_4b,
    dqc.trypsin_2a,
    dqc.trypsin_2c,
    dqc.ms2_rep_ion_all,
    dqc.ms2_rep_ion_1missing,
    dqc.ms2_rep_ion_2missing,
    dqc.ms2_rep_ion_3missing,
    dqc.mass_error_ppm_refined,
    dqc.last_affected AS smaqc_last_affected,
    dqc.psm_source_job,
    dqc.qcdm,
    dqc.qcdm_last_affected,
    dqc.qcart,
    ds.separation_type
   FROM (((public.t_dataset_qc dqc
     JOIN public.t_dataset ds ON ((dqc.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name drn ON ((ds.dataset_rating_id = drn.dataset_rating_id)));


ALTER VIEW public.v_dataset_qc_metrics_export OWNER TO d3l243;

--
-- Name: VIEW v_dataset_qc_metrics_export; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_dataset_qc_metrics_export IS 'LLRC retrieves data with this view, including filtering on separation_type';

--
-- Name: TABLE v_dataset_qc_metrics_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_qc_metrics_export TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_qc_metrics_export TO writeaccess;

