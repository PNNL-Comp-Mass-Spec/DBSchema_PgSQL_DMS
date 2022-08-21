--
-- Name: t_log_entries; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_log_entries (
    entry_id integer NOT NULL,
    posted_by public.citext,
    posting_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type public.citext,
    message public.citext,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE dpkg.t_log_entries OWNER TO d3l243;

--
-- Name: t_log_entries_entry_id_seq; Type: SEQUENCE; Schema: dpkg; Owner: d3l243
--

ALTER TABLE dpkg.t_log_entries ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME dpkg.t_log_entries_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_log_entries pk_t_log_entries; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_log_entries
    ADD CONSTRAINT pk_t_log_entries PRIMARY KEY (entry_id);

--
-- Name: ix_t_log_entries_posted_by; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_posted_by ON dpkg.t_log_entries USING btree (posted_by);

--
-- Name: ix_t_log_entries_posting_time; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_posting_time ON dpkg.t_log_entries USING btree (posting_time);

--
-- Name: TABLE t_log_entries; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_log_entries TO readaccess;
GRANT SELECT,INSERT ON TABLE dpkg.t_log_entries TO writeaccess;

--
-- Name: COLUMN t_log_entries.entered_by; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT UPDATE(entered_by) ON TABLE dpkg.t_log_entries TO writeaccess;

