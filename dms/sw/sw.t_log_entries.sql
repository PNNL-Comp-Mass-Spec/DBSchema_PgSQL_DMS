--
-- Name: t_log_entries; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_log_entries (
    entry_id integer NOT NULL,
    posted_by public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type public.citext,
    message public.citext,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE sw.t_log_entries OWNER TO d3l243;

--
-- Name: t_log_entries_entry_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_log_entries ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_log_entries_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_log_entries pk_t_log_entries; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_log_entries
    ADD CONSTRAINT pk_t_log_entries PRIMARY KEY (entry_id);

--
-- Name: ix_t_log_entries_entered; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_entered ON sw.t_log_entries USING btree (entered);

--
-- Name: ix_t_log_entries_posted_by; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_posted_by ON sw.t_log_entries USING btree (posted_by);

--
-- Name: TABLE t_log_entries; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_log_entries TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_log_entries TO writeaccess;
GRANT INSERT,UPDATE ON TABLE sw.t_log_entries TO dmswebuser;

--
-- Name: COLUMN t_log_entries.entered_by; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT UPDATE(entered_by) ON TABLE sw.t_log_entries TO writeaccess;

