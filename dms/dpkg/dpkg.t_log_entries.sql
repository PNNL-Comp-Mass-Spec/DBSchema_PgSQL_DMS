--
-- Name: t_log_entries; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_log_entries (
    entry_id integer NOT NULL,
    posted_by public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
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

ALTER TABLE dpkg.t_log_entries CLUSTER ON pk_t_log_entries;

--
-- Name: ix_t_log_entries_entered; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_entered ON dpkg.t_log_entries USING btree (entered);

--
-- Name: ix_t_log_entries_posted_by; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_posted_by ON dpkg.t_log_entries USING btree (posted_by);

--
-- Name: TABLE t_log_entries; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_log_entries TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE dpkg.t_log_entries TO writeaccess;
GRANT INSERT,UPDATE ON TABLE dpkg.t_log_entries TO dmswebuser;

