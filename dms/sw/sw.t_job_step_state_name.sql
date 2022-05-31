--
-- Name: t_job_step_state_name; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_step_state_name (
    step_state_id smallint NOT NULL,
    step_state public.citext NOT NULL,
    description public.citext
);


ALTER TABLE sw.t_job_step_state_name OWNER TO d3l243;

--
-- Name: t_job_step_state_name pk_t_step_state; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_step_state_name
    ADD CONSTRAINT pk_t_step_state PRIMARY KEY (step_state_id);

