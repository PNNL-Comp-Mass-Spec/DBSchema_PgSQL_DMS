--
-- Name: t_tasks_history; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_tasks_history (
    job integer NOT NULL,
    priority integer,
    script public.citext,
    state integer NOT NULL,
    dataset public.citext,
    dataset_id integer,
    results_folder_name public.citext,
    imported timestamp without time zone,
    start timestamp without time zone,
    finish timestamp without time zone,
    saved timestamp without time zone NOT NULL,
    most_recent_entry smallint DEFAULT 0 NOT NULL
);


ALTER TABLE cap.t_tasks_history OWNER TO d3l243;

--
-- Name: t_tasks_job_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_tasks ALTER COLUMN job ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_tasks_job_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_tasks_history pk_t_tasks_history; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_tasks_history
    ADD CONSTRAINT pk_t_tasks_history PRIMARY KEY (job, saved);

--
-- Name: ix_t_tasks_history_dataset; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_dataset ON cap.t_tasks_history USING btree (dataset);

--
-- Name: ix_t_tasks_history_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_job ON cap.t_tasks_history USING btree (job);

--
-- Name: ix_t_tasks_history_newest_entry_include_job_script_ds; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_newest_entry_include_job_script_ds ON cap.t_tasks_history USING btree (most_recent_entry) INCLUDE (job, script, dataset);

--
-- Name: ix_t_tasks_history_script_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_script_job ON cap.t_tasks_history USING btree (script) INCLUDE (job);

--
-- Name: ix_t_tasks_history_state_include_job; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_tasks_history_state_include_job ON cap.t_tasks_history USING btree (state) INCLUDE (job);

