--
-- Name: t_log_entries; Type: TABLE; Schema: logsw; Owner: d3l243
--

CREATE TABLE logsw.t_log_entries (
    entry_id integer NOT NULL,
    posted_by public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type public.citext,
    message public.citext,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE logsw.t_log_entries OWNER TO d3l243;

--
-- Name: t_log_entries pk_t_log_entries; Type: CONSTRAINT; Schema: logsw; Owner: d3l243
--

ALTER TABLE ONLY logsw.t_log_entries
    ADD CONSTRAINT pk_t_log_entries PRIMARY KEY (entry_id);

ALTER TABLE logsw.t_log_entries CLUSTER ON pk_t_log_entries;

--
-- Name: ix_t_log_entries_entered; Type: INDEX; Schema: logsw; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_entered ON logsw.t_log_entries USING btree (entered);

--
-- Name: ix_t_log_entries_posted_by; Type: INDEX; Schema: logsw; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_posted_by ON logsw.t_log_entries USING btree (posted_by);

--
-- Name: TABLE t_log_entries; Type: ACL; Schema: logsw; Owner: d3l243
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE logsw.t_log_entries TO writeaccess;

