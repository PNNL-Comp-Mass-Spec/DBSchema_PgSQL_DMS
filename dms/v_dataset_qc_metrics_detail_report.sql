--
-- Name: v_dataset_qc_metrics_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_qc_metrics_detail_report AS
 SELECT DISTINCT dataq.instrument_group,
    dataq.instrument,
    dataq.acq_time_start,
    dataq.dataset_id,
    dataq.dataset,
    dataq.dataset_folder_path,
    dataq.qc_metric_stats,
    dataq.quameter_job,
    (dataq.xic_wide_frac || '| Fraction of precursor ions accounting for the top half of all peak width'::text) AS xic_wide_frac,
    (dataq.xic_fwhm_q1 || ' seconds| 25%ile of peak widths for the wide XICs'::text) AS xic_fwhm_q1,
    (dataq.xic_fwhm_q2 || ' seconds| 50%ile of peak widths for the wide XICs'::text) AS xic_fwhm_q2,
    (dataq.xic_fwhm_q3 || ' seconds| 75%ile of peak widths for the wide XICs'::text) AS xic_fwhm_q3,
    (dataq.xic_height_q2 || '| The log ratio for 50%ile of wide XIC heights over 25%ile of heights.'::text) AS xic_height_q2,
    (dataq.xic_height_q3 || '| The log ratio for 75%ile of wide XIC heights over 50%ile of heights.'::text) AS xic_height_q3,
    (dataq.xic_height_q4 || '| The log ratio for maximum of wide XIC heights over 75%ile of heights.'::text) AS xic_height_q4,
    (dataq.rt_duration || ' seconds| Highest scan time observed minus the lowest scan time observed'::text) AS rt_duration,
    (dataq.rt_tic_q1 || '| The interval when the first 25% of TIC accumulates divided by RT-Duration'::text) AS rt_tic_q1,
    (dataq.rt_tic_q2 || '| The interval when the second 25% of TIC accumulates divided by RT-Duration'::text) AS rt_tic_q2,
    (dataq.rt_tic_q3 || '| The interval when the third 25% of TIC accumulates divided by RT-Duration'::text) AS rt_tic_q3,
    (dataq.rt_tic_q4 || '| The interval when the fourth 25% of TIC accumulates divided by RT-Duration'::text) AS rt_tic_q4,
    (dataq.rt_ms_q1 || '| The interval for the first 25% of all MS events divided by RT-Duration'::text) AS rt_ms_q1,
    (dataq.rt_ms_q2 || '| The interval for the second 25% of all MS events divided by RT-Duration'::text) AS rt_ms_q2,
    (dataq.rt_ms_q3 || '| The interval for the third 25% of all MS events divided by RT-Duration'::text) AS rt_ms_q3,
    (dataq.rt_ms_q4 || '| The interval for the fourth 25% of all MS events divided by RT-Duration'::text) AS rt_ms_q4,
    (dataq.rt_msms_q1 || '| The interval for the first 25% of all MS/MS events divided by RT-Duration'::text) AS rt_msms_q1,
    (dataq.rt_msms_q2 || '| The interval for the second 25% of all MS/MS events divided by RT-Duration'::text) AS rt_msms_q2,
    (dataq.rt_msms_q3 || '| The interval for the third 25% of all MS/MS events divided by RT-Duration'::text) AS rt_msms_q3,
    (dataq.rt_msms_q4 || '| The interval for the fourth 25% of all MS/MS events divided by RT-Duration'::text) AS rt_msms_q4,
    (dataq.ms1_tic_change_q2 || '| The log ratio for 50%ile of TIC changes over 25%ile of TIC changes'::text) AS ms1_tic_change_q2,
    (dataq.ms1_tic_change_q3 || '| The log ratio for 75%ile of TIC changes over 50%ile of TIC changes'::text) AS ms1_tic_change_q3,
    (dataq.ms1_tic_change_q4 || '| The log ratio for largest TIC change over 75%ile of TIC changes'::text) AS ms1_tic_change_q4,
    (dataq.ms1_tic_q2 || '| The log ratio for 50%ile of TIC over 25%ile of TIC'::text) AS ms1_tic_q2,
    (dataq.ms1_tic_q3 || '| The log ratio for 75%ile of TIC over 50%ile of TIC'::text) AS ms1_tic_q3,
    (dataq.ms1_tic_q4 || '| The log ratio for largest TIC over 75%ile TIC'::text) AS ms1_tic_q4,
    (dataq.ms1_count || '| Number of MS spectra collected'::text) AS ms1_count,
    (dataq.ms1_freq_max || ' Hz| Fastest frequency for MS collection in any minute'::text) AS ms1_freq_max,
    (dataq.ms1_density_q1 || '| 25%ile of MS scan peak counts'::text) AS ms1_density_q1,
    (dataq.ms1_density_q2 || '| 50%ile of MS scan peak counts'::text) AS ms1_density_q2,
    (dataq.ms1_density_q3 || '| 75%ile of MS scan peak counts'::text) AS ms1_density_q3,
    (dataq.ms2_count || '| Number of MS/MS spectra collected'::text) AS ms2_count,
    (dataq.ms2_freq_max || ' Hz| Fastest frequency for MS/MS collection in any minute'::text) AS ms2_freq_max,
    (dataq.ms2_density_q1 || '| 25%ile of MS/MS scan peak counts'::text) AS ms2_density_q1,
    (dataq.ms2_density_q2 || '| 50%ile of MS/MS scan peak counts'::text) AS ms2_density_q2,
    (dataq.ms2_density_q3 || '| 75%ile of MS/MS scan peak counts'::text) AS ms2_density_q3,
    (dataq.ms2_prec_z_1 || '| Fraction of MS/MS precursors that are singly charged'::text) AS ms2_prec_z_1,
    (dataq.ms2_prec_z_2 || '| Fraction of MS/MS precursors that are doubly charged'::text) AS ms2_prec_z_2,
    (dataq.ms2_prec_z_3 || '| Fraction of MS/MS precursors that are triply charged'::text) AS ms2_prec_z_3,
    (dataq.ms2_prec_z_4 || '| Fraction of MS/MS precursors that are quadruply charged'::text) AS ms2_prec_z_4,
    (dataq.ms2_prec_z_5 || '| Fraction of MS/MS precursors that are quintuply charged'::text) AS ms2_prec_z_5,
    (dataq.ms2_prec_z_more || '| Fraction of MS/MS precursors that are charged higher than +5'::text) AS ms2_prec_z_more,
    (dataq.ms2_prec_z_likely_1 || '| Fraction of MS/MS precursors lack known charge but look like 1+'::text) AS ms2_prec_z_likely_1,
    (dataq.ms2_prec_z_likely_multi || '| Fraction of MS/MS precursors lack known charge but look like 2+ or higher'::text) AS ms2_prec_z_likely_multi,
    dataq.quameter_last_affected,
    dataq.smaqc_job,
    (dataq.c_1a || '| Fraction of peptides identified more than 4 minutes earlier than the chromatographic peak apex'::text) AS c_1a,
    (dataq.c_1b || '| Fraction of peptides identified more than 4 minutes later than the chromatographic peak apex'::text) AS c_1b,
    (dataq.c_2a || ' minutes| Time period over which 50% of peptides are identified'::text) AS c_2a,
    (dataq.c_2b || '| Rate of peptide identification during C-2A'::text) AS c_2b,
    (dataq.c_3a || ' seconds| Median peak width for all peptides'::text) AS c_3a,
    (dataq.c_3b || ' seconds| Median peak width during middle 50% of separation'::text) AS c_3b,
    (dataq.c_4a || ' seconds| Median peak width during first 10% of separation'::text) AS c_4a,
    (dataq.c_4b || ' seconds| Median peak width during last 10% of separation'::text) AS c_4b,
    (dataq.c_4c || ' seconds| Median peak width during middle 10% of separation'::text) AS c_4c,
    (dataq.ds_1a || '| Count of peptides with one spectrum / count of peptides with two spectra'::text) AS ds_1a,
    (dataq.ds_1b || '| Count of peptides with two spectra / count of peptides with three spectra'::text) AS ds_1b,
    (dataq.ds_2a || '| Number of MS1 scans taken over middle 50% of separation'::text) AS ds_2a,
    (dataq.ds_2b || '| Number of MS2 scans taken over middle 50% of separation'::text) AS ds_2b,
    (dataq.ds_3a || '| Median of MS1 max / MS1 sampled abundance'::text) AS ds_3a,
    (dataq.ds_3b || '| Median of MS1 max / MS1 sampled abundance; limit to bottom 50% of peptides by abundance'::text) AS ds_3b,
    (dataq.is_1a || '| Occurrences of MS1 jumping >10x'::text) AS is_1a,
    (dataq.is_1b || '| Occurrences of MS1 falling >10x'::text) AS is_1b,
    (dataq.is_2 || '| Median precursor m/z for all peptides'::text) AS is_2,
    (dataq.is_3a || '| Count of 1+ peptides / count of 2+ peptides'::text) AS is_3a,
    (dataq.is_3b || '| Count of 3+ peptides / count of 2+ peptides'::text) AS is_3b,
    (dataq.is_3c || '| Count of 4+ peptides / count of 2+ peptides'::text) AS is_3c,
    (dataq.ms1_1 || ' milliseconds| Median MS1 ion injection time'::text) AS ms1_1,
    (dataq.ms1_2a || '| Median S/N value for MS1 spectra from run start through middle 50% of separation'::text) AS ms1_2a,
    (dataq.ms1_2b || '| Median TIC value for identified peptides from run start through middle 50% of separation'::text) AS ms1_2b,
    (dataq.ms1_3a || '| Dynamic range estimate using 95th percentile peptide peak apex intensity / 5th percentile'::text) AS ms1_3a,
    (dataq.ms1_3b || '| Median peak apex intensity for all peptides'::text) AS ms1_3b,
    (dataq.ms1_5a || ' Th| Median of precursor mass error'::text) AS ms1_5a,
    (dataq.ms1_5b || ' Th| Median of absolute value of precursor mass error'::text) AS ms1_5b,
    (dataq.ms1_5c || ' ppm| Median of precursor mass error'::text) AS ms1_5c,
    (dataq.ms1_5d || ' ppm| Interquartile distance in ppm-based precursor mass error'::text) AS ms1_5d,
    (dataq.ms2_1 || ' milliseconds| Median MS2 ion injection time for identified peptides'::text) AS ms2_1,
    (dataq.ms2_2 || '| Median S/N value for identified MS2 spectra'::text) AS ms2_2,
    (dataq.ms2_3 || '| Median number of peaks in all MS2 spectra'::text) AS ms2_3,
    (dataq.ms2_4a || '| Fraction of all MS2 spectra identified; low abundance quartile (determined using MS1 intensity of identified peptides)'::text) AS ms2_4a,
    (dataq.ms2_4b || '| Fraction of all MS2 spectra identified; second quartile (determined using MS1 intensity of identified peptides)'::text) AS ms2_4b,
    (dataq.ms2_4c || '| Fraction of all MS2 spectra identified; third quartile (determined using MS1 intensity of identified peptides)'::text) AS ms2_4c,
    (dataq.ms2_4d || '| Fraction of all MS2 spectra identified; high abundance quartile (determined using MS1 intensity of identified peptides)'::text) AS ms2_4d,
    (dataq.p_1a || '| Median peptide ID score (-Log10(MSGF_SpecProb) or X!Tandem hyperscore)'::text) AS p_1a,
    (dataq.p_1b || '| Median peptide ID score ( Log10(MSGF_SpecProb) or X!Tandem Peptide_Expectation_Value_Log(e))'::text) AS p_1b,
    (dataq.p_2a || '| Number of tryptic peptides; total spectra count'::text) AS p_2a,
    (dataq.p_2b || '| Number of tryptic peptides; unique peptide & charge count'::text) AS p_2b,
    (dataq.p_2c || '| Number of tryptic peptides; unique peptide count'::text) AS p_2c,
    (dataq.p_3 || '| Ratio of unique semi-tryptic / unique fully tryptic peptides'::text) AS p_3,
    (dataq.phos_2a || '| Number of tryptic phosphopeptides; total spectra count'::text) AS phos_2a,
    (dataq.phos_2c || '| Number of tryptic phosphopeptides; unique peptide count'::text) AS phos_2c,
    (dataq.keratin_2a || '| Number of keratin peptides (full or partial trypsin); total spectra count'::text) AS keratin_2a,
    (dataq.keratin_2c || '| Number of keratin peptides (full or partial trypsin); unique peptide count'::text) AS keratin_2c,
    (dataq.p_4a || '| Ratio of unique fully tryptic peptides / total unique peptides'::text) AS p_4a,
    (dataq.p_4b || '| Ratio of total missed cleavages (among unique peptides) / total unique peptides'::text) AS p_4b,
    (dataq.trypsin_2a || '| Number of peptides from trypsin; total spectra count'::text) AS trypsin_2a,
    (dataq.trypsin_2c || '| Number of peptides from trypsin; unique peptide count'::text) AS trypsin_2c,
    (dataq.ms2_rep_ion_all || '| Number of peptides (PSMs) where all reporter ions were seen'::text) AS ms2_rep_ion_all,
    (dataq.ms2_rep_ion_1missing || '| Number of peptides (PSMs) where all but 1 of the reporter ions were seen'::text) AS ms2_rep_ion_1missing,
    (dataq.ms2_rep_ion_2missing || '| Number of peptides (PSMs) where all but 2 of the reporter ions were seen'::text) AS ms2_rep_ion_2missing,
    (dataq.ms2_rep_ion_3missing || '| Number of peptides (PSMs) where all but 3 of the reporter ions were seen'::text) AS ms2_rep_ion_3missing,
    dataq.smaqc_last_affected,
    (dataq.qcdm || '| Overall confidence using model developed by Brett Amidan'::text) AS qcdm,
    dataq.qcdm_last_affected,
    dataq.mass_error_ppm,
    dataq.mass_error_ppm_refined,
    dataq.mass_error_ppm_viper,
    dataq.amts_10pct_fdr,
    (dataq.qcart || '| Overall confidence using model developed by Allison Thompson and Ryan Butner'::text) AS qcart
   FROM ( SELECT instname.instrument_group,
            instname.instrument,
            ds.acq_time_start,
            dqc.dataset_id,
            ds.dataset,
            dfp.dataset_folder_path,
            ('http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/'::text || (instname.instrument)::text) AS qc_metric_stats,
            dqc.quameter_job,
            public.number_to_string((dqc.xic_wide_frac)::double precision, 3) AS xic_wide_frac,
            public.number_to_string((dqc.xic_fwhm_q1)::double precision, 3) AS xic_fwhm_q1,
            public.number_to_string((dqc.xic_fwhm_q2)::double precision, 3) AS xic_fwhm_q2,
            public.number_to_string((dqc.xic_fwhm_q3)::double precision, 3) AS xic_fwhm_q3,
            public.number_to_string((dqc.xic_height_q2)::double precision, 3) AS xic_height_q2,
            public.number_to_string((dqc.xic_height_q3)::double precision, 3) AS xic_height_q3,
            public.number_to_string((dqc.xic_height_q4)::double precision, 3) AS xic_height_q4,
            public.number_to_string((dqc.rt_duration)::double precision, 3) AS rt_duration,
            public.number_to_string((dqc.rt_tic_q1)::double precision, 3) AS rt_tic_q1,
            public.number_to_string((dqc.rt_tic_q2)::double precision, 3) AS rt_tic_q2,
            public.number_to_string((dqc.rt_tic_q3)::double precision, 3) AS rt_tic_q3,
            public.number_to_string((dqc.rt_tic_q4)::double precision, 3) AS rt_tic_q4,
            public.number_to_string((dqc.rt_ms_q1)::double precision, 3) AS rt_ms_q1,
            public.number_to_string((dqc.rt_ms_q2)::double precision, 3) AS rt_ms_q2,
            public.number_to_string((dqc.rt_ms_q3)::double precision, 3) AS rt_ms_q3,
            public.number_to_string((dqc.rt_ms_q4)::double precision, 3) AS rt_ms_q4,
            public.number_to_string((dqc.rt_msms_q1)::double precision, 3) AS rt_msms_q1,
            public.number_to_string((dqc.rt_msms_q2)::double precision, 3) AS rt_msms_q2,
            public.number_to_string((dqc.rt_msms_q3)::double precision, 3) AS rt_msms_q3,
            public.number_to_string((dqc.rt_msms_q4)::double precision, 3) AS rt_msms_q4,
            public.number_to_string((dqc.ms1_tic_change_q2)::double precision, 3) AS ms1_tic_change_q2,
            public.number_to_string((dqc.ms1_tic_change_q3)::double precision, 3) AS ms1_tic_change_q3,
            public.number_to_string((dqc.ms1_tic_change_q4)::double precision, 3) AS ms1_tic_change_q4,
            public.number_to_string((dqc.ms1_tic_q2)::double precision, 3) AS ms1_tic_q2,
            public.number_to_string((dqc.ms1_tic_q3)::double precision, 3) AS ms1_tic_q3,
            public.number_to_string((dqc.ms1_tic_q4)::double precision, 3) AS ms1_tic_q4,
            public.number_to_string((dqc.ms1_count)::double precision, 0) AS ms1_count,
            public.number_to_string((dqc.ms1_freq_max)::double precision, 3) AS ms1_freq_max,
            public.number_to_string((dqc.ms1_density_q1)::double precision, 0) AS ms1_density_q1,
            public.number_to_string((dqc.ms1_density_q2)::double precision, 0) AS ms1_density_q2,
            public.number_to_string((dqc.ms1_density_q3)::double precision, 0) AS ms1_density_q3,
            public.number_to_string((dqc.ms2_count)::double precision, 0) AS ms2_count,
            public.number_to_string((dqc.ms2_freq_max)::double precision, 3) AS ms2_freq_max,
            public.number_to_string((dqc.ms2_density_q1)::double precision, 0) AS ms2_density_q1,
            public.number_to_string((dqc.ms2_density_q2)::double precision, 0) AS ms2_density_q2,
            public.number_to_string((dqc.ms2_density_q3)::double precision, 0) AS ms2_density_q3,
            public.number_to_string((dqc.ms2_prec_z_1)::double precision, 3) AS ms2_prec_z_1,
            public.number_to_string((dqc.ms2_prec_z_2)::double precision, 3) AS ms2_prec_z_2,
            public.number_to_string((dqc.ms2_prec_z_3)::double precision, 3) AS ms2_prec_z_3,
            public.number_to_string((dqc.ms2_prec_z_4)::double precision, 3) AS ms2_prec_z_4,
            public.number_to_string((dqc.ms2_prec_z_5)::double precision, 3) AS ms2_prec_z_5,
            public.number_to_string((dqc.ms2_prec_z_more)::double precision, 3) AS ms2_prec_z_more,
            public.number_to_string((dqc.ms2_prec_z_likely_1)::double precision, 3) AS ms2_prec_z_likely_1,
            public.number_to_string((dqc.ms2_prec_z_likely_multi)::double precision, 3) AS ms2_prec_z_likely_multi,
            dqc.quameter_last_affected,
            dqc.smaqc_job,
            public.number_to_string((dqc.c_1a)::double precision, 3) AS c_1a,
            public.number_to_string((dqc.c_1b)::double precision, 3) AS c_1b,
            public.number_to_string((dqc.c_2a)::double precision, 3) AS c_2a,
            public.number_to_string((dqc.c_2b)::double precision, 3) AS c_2b,
            public.number_to_string((dqc.c_3a)::double precision, 3) AS c_3a,
            public.number_to_string((dqc.c_3b)::double precision, 3) AS c_3b,
            public.number_to_string((dqc.c_4a)::double precision, 3) AS c_4a,
            public.number_to_string((dqc.c_4b)::double precision, 3) AS c_4b,
            public.number_to_string((dqc.c_4c)::double precision, 3) AS c_4c,
            public.number_to_string((dqc.ds_1a)::double precision, 3) AS ds_1a,
            public.number_to_string((dqc.ds_1b)::double precision, 3) AS ds_1b,
            public.number_to_string((dqc.ds_2a)::double precision, 0) AS ds_2a,
            public.number_to_string((dqc.ds_2b)::double precision, 0) AS ds_2b,
            public.number_to_string((dqc.ds_3a)::double precision, 3) AS ds_3a,
            public.number_to_string((dqc.ds_3b)::double precision, 3) AS ds_3b,
            public.number_to_string((dqc.is_1a)::double precision, 0) AS is_1a,
            public.number_to_string((dqc.is_1b)::double precision, 0) AS is_1b,
            public.number_to_string((dqc.is_2)::double precision, 3) AS is_2,
            public.number_to_string((dqc.is_3a)::double precision, 3) AS is_3a,
            public.number_to_string((dqc.is_3b)::double precision, 3) AS is_3b,
            public.number_to_string((dqc.is_3c)::double precision, 3) AS is_3c,
            public.number_to_string((dqc.ms1_1)::double precision, 3) AS ms1_1,
            public.number_to_string((dqc.ms1_2a)::double precision, 3) AS ms1_2a,
            public.number_to_string((dqc.ms1_2b)::double precision, 3) AS ms1_2b,
            public.number_to_string((dqc.ms1_3a)::double precision, 3) AS ms1_3a,
            public.number_to_string((dqc.ms1_3b)::double precision, 3) AS ms1_3b,
            public.number_to_string((dqc.ms1_5a)::double precision, 3) AS ms1_5a,
            public.number_to_string((dqc.ms1_5b)::double precision, 3) AS ms1_5b,
            public.number_to_string((dqc.ms1_5c)::double precision, 3) AS ms1_5c,
            public.number_to_string((dqc.ms1_5d)::double precision, 3) AS ms1_5d,
            public.number_to_string((dqc.ms2_1)::double precision, 3) AS ms2_1,
            public.number_to_string((dqc.ms2_2)::double precision, 3) AS ms2_2,
            public.number_to_string((dqc.ms2_3)::double precision, 0) AS ms2_3,
            public.number_to_string((dqc.ms2_4a)::double precision, 3) AS ms2_4a,
            public.number_to_string((dqc.ms2_4b)::double precision, 3) AS ms2_4b,
            public.number_to_string((dqc.ms2_4c)::double precision, 3) AS ms2_4c,
            public.number_to_string((dqc.ms2_4d)::double precision, 3) AS ms2_4d,
            public.number_to_string((dqc.p_1a)::double precision, 3) AS p_1a,
            public.number_to_string((dqc.p_1b)::double precision, 3) AS p_1b,
            public.number_to_string((dqc.p_2a)::double precision, 0) AS p_2a,
            public.number_to_string((dqc.p_2b)::double precision, 0) AS p_2b,
            public.number_to_string((dqc.p_2c)::double precision, 0) AS p_2c,
            public.number_to_string((dqc.p_3)::double precision, 3) AS p_3,
            public.number_to_string((dqc.phos_2a)::double precision, 0) AS phos_2a,
            public.number_to_string((dqc.phos_2c)::double precision, 0) AS phos_2c,
            public.number_to_string((dqc.keratin_2a)::double precision, 0) AS keratin_2a,
            public.number_to_string((dqc.keratin_2c)::double precision, 0) AS keratin_2c,
            public.number_to_string((dqc.p_4a)::double precision, 3) AS p_4a,
            public.number_to_string((dqc.p_4b)::double precision, 3) AS p_4b,
            public.number_to_string((dqc.trypsin_2a)::double precision, 0) AS trypsin_2a,
            public.number_to_string((dqc.trypsin_2c)::double precision, 0) AS trypsin_2c,
            public.number_to_string(dqc.ms2_rep_ion_all, 0) AS ms2_rep_ion_all,
            public.number_to_string(dqc.ms2_rep_ion_1missing, 0) AS ms2_rep_ion_1missing,
            public.number_to_string(dqc.ms2_rep_ion_2missing, 0) AS ms2_rep_ion_2missing,
            public.number_to_string(dqc.ms2_rep_ion_3missing, 0) AS ms2_rep_ion_3missing,
            dqc.last_affected AS smaqc_last_affected,
            public.number_to_string((dqc.qcdm)::double precision, 3) AS qcdm,
            dqc.qcdm_last_affected,
            public.number_to_string((dqc.mass_error_ppm)::double precision, 3) AS mass_error_ppm,
            public.number_to_string((dqc.mass_error_ppm_refined)::double precision, 3) AS mass_error_ppm_refined,
            public.number_to_string(dqc.mass_error_ppm_viper, 3) AS mass_error_ppm_viper,
            dqc.amts_10pct_fdr,
            public.number_to_string((dqc.qcart)::double precision, 3) AS qcart
           FROM (((public.t_dataset_qc dqc
             JOIN public.t_dataset ds ON ((dqc.dataset_id = ds.dataset_id)))
             JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
             LEFT JOIN public.v_dataset_folder_paths dfp ON ((dqc.dataset_id = dfp.dataset_id)))) dataq;


ALTER TABLE public.v_dataset_qc_metrics_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_qc_metrics_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_qc_metrics_detail_report TO readaccess;

