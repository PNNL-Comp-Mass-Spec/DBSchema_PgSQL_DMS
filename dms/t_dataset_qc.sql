--
-- Name: t_dataset_qc; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_qc (
    dataset_id integer NOT NULL,
    smaqc_job integer,
    psm_source_job integer,
    last_affected timestamp without time zone,
    c_1a real,
    c_1b real,
    c_2a real,
    c_2b real,
    c_3a real,
    c_3b real,
    c_4a real,
    c_4b real,
    c_4c real,
    ds_1a real,
    ds_1b real,
    ds_2a real,
    ds_2b real,
    ds_3a real,
    ds_3b real,
    is_1a real,
    is_1b real,
    is_2 real,
    is_3a real,
    is_3b real,
    is_3c real,
    ms1_1 real,
    ms1_2a real,
    ms1_2b real,
    ms1_3a real,
    ms1_3b real,
    ms1_5a real,
    ms1_5b real,
    ms1_5c real,
    ms1_5d real,
    ms2_1 real,
    ms2_2 real,
    ms2_3 real,
    ms2_4a real,
    ms2_4b real,
    ms2_4c real,
    ms2_4d real,
    p_1a real,
    p_1b real,
    p_2a real,
    p_2b real,
    p_2c real,
    p_3 real,
    quameter_job integer,
    quameter_last_affected timestamp without time zone,
    xic_wide_frac real,
    xic_fwhm_q1 real,
    xic_fwhm_q2 real,
    xic_fwhm_q3 real,
    xic_height_q2 real,
    xic_height_q3 real,
    xic_height_q4 real,
    rt_duration real,
    rt_tic_q1 real,
    rt_tic_q2 real,
    rt_tic_q3 real,
    rt_tic_q4 real,
    rt_ms_q1 real,
    rt_ms_q2 real,
    rt_ms_q3 real,
    rt_ms_q4 real,
    rt_msms_q1 real,
    rt_msms_q2 real,
    rt_msms_q3 real,
    rt_msms_q4 real,
    ms1_tic_change_q2 real,
    ms1_tic_change_q3 real,
    ms1_tic_change_q4 real,
    ms1_tic_q2 real,
    ms1_tic_q3 real,
    ms1_tic_q4 real,
    ms1_count real,
    ms1_freq_max real,
    ms1_density_q1 real,
    ms1_density_q2 real,
    ms1_density_q3 real,
    ms2_count real,
    ms2_freq_max real,
    ms2_density_q1 real,
    ms2_density_q2 real,
    ms2_density_q3 real,
    ms2_prec_z_1 real,
    ms2_prec_z_2 real,
    ms2_prec_z_3 real,
    ms2_prec_z_4 real,
    ms2_prec_z_5 real,
    ms2_prec_z_more real,
    ms2_prec_z_likely_1 real,
    ms2_prec_z_likely_multi real,
    qcdm_last_affected timestamp without time zone,
    qcdm real,
    mass_error_ppm real,
    mass_error_ppm_refined real,
    mass_error_ppm_viper numeric(9,4),
    amts_10pct_fdr integer,
    amts_25pct_fdr integer,
    phos_2a real,
    phos_2c real,
    keratin_2a real,
    keratin_2c real,
    p_4a real,
    p_4b real,
    qcart real,
    trypsin_2a real,
    trypsin_2c real,
    ms2_rep_ion_all double precision,
    ms2_rep_ion_1missing double precision,
    ms2_rep_ion_2missing double precision,
    ms2_rep_ion_3missing double precision
);


ALTER TABLE public.t_dataset_qc OWNER TO d3l243;

--
-- Name: t_dataset_qc pk_t_dataset_qc_dataset_id; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_qc
    ADD CONSTRAINT pk_t_dataset_qc_dataset_id PRIMARY KEY (dataset_id);

ALTER TABLE public.t_dataset_qc CLUSTER ON pk_t_dataset_qc_dataset_id;

--
-- Name: t_dataset_qc fk_t_dataset_qc_t_dataset; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_qc
    ADD CONSTRAINT fk_t_dataset_qc_t_dataset FOREIGN KEY (dataset_id) REFERENCES public.t_dataset(dataset_id);

--
-- Name: TABLE t_dataset_qc; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_qc TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_dataset_qc TO writeaccess;

