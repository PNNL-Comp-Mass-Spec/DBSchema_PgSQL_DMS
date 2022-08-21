--
-- Name: t_analysis_job_psm_stats_phospho; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_psm_stats_phospho (
    job integer NOT NULL,
    phosphopeptides integer NOT NULL,
    cterm_k_phosphopeptides integer NOT NULL,
    cterm_r_phosphopeptides integer NOT NULL,
    missed_cleavage_ratio real NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_analysis_job_psm_stats_phospho OWNER TO d3l243;

--
-- Name: t_analysis_job_psm_stats_phospho pk_t_analysis_job_psm_stats_phospho; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_psm_stats_phospho
    ADD CONSTRAINT pk_t_analysis_job_psm_stats_phospho PRIMARY KEY (job);

--
-- Name: TABLE t_analysis_job_psm_stats_phospho; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_psm_stats_phospho TO readaccess;
GRANT SELECT ON TABLE public.t_analysis_job_psm_stats_phospho TO writeaccess;

