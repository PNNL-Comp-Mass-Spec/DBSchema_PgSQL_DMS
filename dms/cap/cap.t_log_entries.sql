--
-- Name: t_log_entries; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_log_entries (
    entry_id integer NOT NULL,
    posted_by public.citext,
    posting_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type public.citext,
    message public.citext,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE cap.t_log_entries OWNER TO d3l243;

--
-- Name: t_log_entries_entry_id_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_log_entries ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_log_entries_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_log_entries pk_t_log_entries; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_log_entries
    ADD CONSTRAINT pk_t_log_entries PRIMARY KEY (entry_id);

--
-- Name: ix_t_log_entries_posted_by; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_posted_by ON cap.t_log_entries USING btree (posted_by);

--
-- Name: ix_t_log_entries_posting_time; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_posting_time ON cap.t_log_entries USING btree (posting_time);

--
-- Name: TABLE t_log_entries; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_log_entries TO readaccess;

