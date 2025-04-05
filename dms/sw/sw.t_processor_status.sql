--
-- Name: t_processor_status; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_processor_status (
    processor_name public.citext NOT NULL,
    mgr_status public.citext,
    status_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_start_time timestamp without time zone,
    cpu_utilization real,
    free_memory_mb real,
    process_id integer,
    prog_runner_process_id integer,
    prog_runner_core_usage real,
    most_recent_error_message public.citext,
    step_tool public.citext,
    task_status public.citext,
    duration_hours real,
    progress real,
    current_operation public.citext,
    task_detail_status public.citext,
    job integer,
    job_step integer,
    dataset public.citext,
    most_recent_log_message public.citext,
    most_recent_job_info public.citext,
    spectrum_count integer,
    monitor_processor smallint DEFAULT 1 NOT NULL,
    remote_manager public.citext DEFAULT ''::public.citext NOT NULL,
    remote_processor smallint DEFAULT 0 NOT NULL
);


ALTER TABLE sw.t_processor_status OWNER TO d3l243;

--
-- Name: t_processor_status pk_t_processor_status; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_processor_status
    ADD CONSTRAINT pk_t_processor_status PRIMARY KEY (processor_name);

ALTER TABLE sw.t_processor_status CLUSTER ON pk_t_processor_status;

--
-- Name: ix_t_processor_status_monitor_processor; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_processor_status_monitor_processor ON sw.t_processor_status USING btree (monitor_processor) INCLUDE (processor_name);

--
-- Name: TABLE t_processor_status; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_processor_status TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_processor_status TO writeaccess;

