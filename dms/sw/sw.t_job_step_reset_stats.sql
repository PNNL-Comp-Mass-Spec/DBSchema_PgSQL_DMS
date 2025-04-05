--
-- Name: t_job_step_reset_stats; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_step_reset_stats (
    job integer NOT NULL,
    step integer NOT NULL,
    tool public.citext NOT NULL,
    disk_space_count integer DEFAULT 0 NOT NULL,
    memory_count integer DEFAULT 0 NOT NULL,
    comment public.citext DEFAULT ''::public.citext NOT NULL,
    dataset_id integer,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE sw.t_job_step_reset_stats OWNER TO d3l243;

--
-- Name: TABLE t_job_step_reset_stats; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON TABLE sw.t_job_step_reset_stats IS 'Column disk_space_count tracks the number of times the given job step was reset due to insufficient free disk space; column memory_count tracks the number of times the given job step was reset due to insufficient available memory';

--
-- Name: t_job_step_reset_stats pk_t_job_step_reset_stats; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_step_reset_stats
    ADD CONSTRAINT pk_t_job_step_reset_stats PRIMARY KEY (job, step);

ALTER TABLE sw.t_job_step_reset_stats CLUSTER ON pk_t_job_step_reset_stats;

--
-- Name: t_job_step_reset_stats fk_t_job_step_reset_stats_t_step_tools; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_step_reset_stats
    ADD CONSTRAINT fk_t_job_step_reset_stats_t_step_tools FOREIGN KEY (tool) REFERENCES sw.t_step_tools(step_tool) ON UPDATE CASCADE;

--
-- Name: TABLE t_job_step_reset_stats; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_job_step_reset_stats TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_job_step_reset_stats TO writeaccess;

