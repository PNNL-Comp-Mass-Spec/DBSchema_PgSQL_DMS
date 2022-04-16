--
-- Name: t_analysis_job_psm_stats; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_psm_stats (
    job integer NOT NULL,
    msgf_threshold double precision NOT NULL,
    fdr_threshold double precision NOT NULL,
    msgf_threshold_is_evalue smallint NOT NULL,
    spectra_searched integer,
    total_psms integer,
    unique_peptides integer,
    unique_proteins integer,
    total_psms_fdr_filter integer,
    unique_peptides_fdr_filter integer,
    unique_proteins_fdr_filter integer,
    missed_cleavage_ratio_fdr real,
    tryptic_peptides_fdr integer,
    keratin_peptides_fdr integer,
    trypsin_peptides_fdr integer,
    acetyl_peptides_fdr integer,
    percent_msn_scans_no_psm real,
    maximum_scan_gap_adjacent_msn integer,
    dynamic_reporter_ion smallint NOT NULL,
    percent_psms_missing_nterm_reporter_ion real,
    percent_psms_missing_reporter_ion real,
    last_affected timestamp without time zone NOT NULL
);


ALTER TABLE public.t_analysis_job_psm_stats OWNER TO d3l243;

--
-- Name: TABLE t_analysis_job_psm_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_psm_stats TO readaccess;

