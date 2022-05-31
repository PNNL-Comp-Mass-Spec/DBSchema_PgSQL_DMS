--
-- Name: t_job_step_processing_stats; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_step_processing_stats (
    entered timestamp without time zone NOT NULL,
    job integer NOT NULL,
    step integer NOT NULL,
    entry_id integer NOT NULL,
    processor public.citext,
    run_time_minutes numeric(9,1),
    job_progress real,
    run_time_predicted_hours numeric(9,2),
    prog_runner_core_usage real,
    cpu_load smallint,
    actual_cpu_load smallint
);


ALTER TABLE sw.t_job_step_processing_stats OWNER TO d3l243;

--
-- Name: t_job_step_processing_stats_entry_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_job_step_processing_stats ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_job_step_processing_stats_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_job_step_processing_stats pk_t_job_step_processing_stats; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_step_processing_stats
    ADD CONSTRAINT pk_t_job_step_processing_stats PRIMARY KEY (entered, job, step);

--
-- Name: ix_t_job_step_processing_stats_entry_id; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_processing_stats_entry_id ON sw.t_job_step_processing_stats USING btree (entry_id);

