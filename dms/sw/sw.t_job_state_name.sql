--
-- Name: t_job_state_name; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_state_name (
    job_state_id integer NOT NULL,
    job_state public.citext
);


ALTER TABLE sw.t_job_state_name OWNER TO d3l243;

--
-- Name: t_job_state_name pk_t_job_state_name; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_state_name
    ADD CONSTRAINT pk_t_job_state_name PRIMARY KEY (job_state_id);

ALTER TABLE sw.t_job_state_name CLUSTER ON pk_t_job_state_name;

--
-- Name: TABLE t_job_state_name; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_job_state_name TO readaccess;
GRANT SELECT ON TABLE sw.t_job_state_name TO writeaccess;

