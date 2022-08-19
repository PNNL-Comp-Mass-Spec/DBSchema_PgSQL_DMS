--
-- Name: t_log_entries; Type: TABLE; Schema: logdms; Owner: d3l243
--

CREATE TABLE logdms.t_log_entries (
    entry_id integer NOT NULL,
    posted_by public.citext,
    posting_time timestamp without time zone NOT NULL,
    type public.citext,
    message public.citext
);


ALTER TABLE logdms.t_log_entries OWNER TO d3l243;

--
-- Name: t_log_entries pk_t_log_entries; Type: CONSTRAINT; Schema: logdms; Owner: d3l243
--

ALTER TABLE ONLY logdms.t_log_entries
    ADD CONSTRAINT pk_t_log_entries PRIMARY KEY (entry_id);

--
-- Name: ix_t_log_entries_posted_by; Type: INDEX; Schema: logdms; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_posted_by ON logdms.t_log_entries USING btree (posted_by);

--
-- Name: ix_t_log_entries_posting_time; Type: INDEX; Schema: logdms; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_posting_time ON logdms.t_log_entries USING btree (posting_time);

--
-- Name: TABLE t_log_entries; Type: ACL; Schema: logdms; Owner: d3l243
--

GRANT SELECT,INSERT ON TABLE logdms.t_log_entries TO writeaccess;

