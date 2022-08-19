--
-- Name: t_processor_status; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_processor_status (
    processor_name public.citext NOT NULL,
    mgr_status public.citext,
    status_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_start_time timestamp without time zone,
    cpu_utilization real,
    free_memory_mb real,
    process_id integer,
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
    remote_status_location public.citext DEFAULT ''::public.citext NOT NULL
);


ALTER TABLE cap.t_processor_status OWNER TO d3l243;

--
-- Name: t_processor_status pk_t_processor_status; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_processor_status
    ADD CONSTRAINT pk_t_processor_status PRIMARY KEY (processor_name);

--
-- Name: ix_t_processor_status_monitor_processor; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_processor_status_monitor_processor ON cap.t_processor_status USING btree (monitor_processor) INCLUDE (processor_name);

--
-- Name: TABLE t_processor_status; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_processor_status TO readaccess;
GRANT SELECT ON TABLE cap.t_processor_status TO writeaccess;

