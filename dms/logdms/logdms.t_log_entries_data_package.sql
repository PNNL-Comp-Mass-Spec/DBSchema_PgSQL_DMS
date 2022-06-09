--
-- Name: t_log_entries_data_package; Type: TABLE; Schema: logdms; Owner: d3l243
--

CREATE TABLE logdms.t_log_entries_data_package (
    entry_id integer NOT NULL,
    posted_by public.citext,
    posting_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    type public.citext,
    message public.citext
);


ALTER TABLE logdms.t_log_entries_data_package OWNER TO d3l243;

--
-- Name: t_log_entries_data_package pk_t_log_entries_data_package; Type: CONSTRAINT; Schema: logdms; Owner: d3l243
--

ALTER TABLE ONLY logdms.t_log_entries_data_package
    ADD CONSTRAINT pk_t_log_entries_data_package PRIMARY KEY (entry_id);

--
-- Name: ix_t_log_entries_data_package_posted_by; Type: INDEX; Schema: logdms; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_data_package_posted_by ON logdms.t_log_entries_data_package USING btree (posted_by);

--
-- Name: ix_t_log_entries_data_package_posting_time; Type: INDEX; Schema: logdms; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_data_package_posting_time ON logdms.t_log_entries_data_package USING btree (posting_time);

