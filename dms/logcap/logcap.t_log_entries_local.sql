--
-- Name: t_log_entries_local; Type: TABLE; Schema: logcap; Owner: d3l243
--

CREATE TABLE logcap.t_log_entries_local (
    entry_id integer NOT NULL,
    posted_by public.citext,
    posting_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type public.citext,
    message public.citext,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE logcap.t_log_entries_local OWNER TO d3l243;

--
-- Name: t_log_entries_local_entry_id_seq; Type: SEQUENCE; Schema: logcap; Owner: d3l243
--

ALTER TABLE logcap.t_log_entries_local ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logcap.t_log_entries_local_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_log_entries_local pk_t_log_entries_local; Type: CONSTRAINT; Schema: logcap; Owner: d3l243
--

ALTER TABLE ONLY logcap.t_log_entries_local
    ADD CONSTRAINT pk_t_log_entries_local PRIMARY KEY (entry_id);

--
-- Name: ix_t_log_entries_local_posted_by; Type: INDEX; Schema: logcap; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_local_posted_by ON logcap.t_log_entries_local USING btree (posted_by);

--
-- Name: ix_t_log_entries_local_posting_time; Type: INDEX; Schema: logcap; Owner: d3l243
--

CREATE INDEX ix_t_log_entries_local_posting_time ON logcap.t_log_entries_local USING btree (posting_time);

