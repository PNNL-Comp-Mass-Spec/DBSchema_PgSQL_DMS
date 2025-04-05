--
-- Name: t_pipeline_job_stats; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_pipeline_job_stats (
    script public.citext NOT NULL,
    instrument_group public.citext NOT NULL,
    year integer NOT NULL,
    jobs integer NOT NULL
);


ALTER TABLE sw.t_pipeline_job_stats OWNER TO d3l243;

--
-- Name: t_pipeline_job_stats pk_t_pipeline_job_stats; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_pipeline_job_stats
    ADD CONSTRAINT pk_t_pipeline_job_stats PRIMARY KEY (script, instrument_group, year);

ALTER TABLE sw.t_pipeline_job_stats CLUSTER ON pk_t_pipeline_job_stats;

--
-- Name: TABLE t_pipeline_job_stats; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_pipeline_job_stats TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_pipeline_job_stats TO writeaccess;

