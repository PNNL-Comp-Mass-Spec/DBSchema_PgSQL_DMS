--
-- Name: t_log_entries; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_log_entries (
    entry_id integer NOT NULL,
    posted_by public.citext,
    posting_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type public.citext,
    message public.citext,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE mc.t_log_entries OWNER TO d3l243;

--
-- Name: t_log_entries_entry_id_seq; Type: SEQUENCE; Schema: mc; Owner: d3l243
--

ALTER TABLE mc.t_log_entries ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mc.t_log_entries_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_log_entries pk_t_log_entries; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_log_entries
    ADD CONSTRAINT pk_t_log_entries PRIMARY KEY (entry_id);

--
-- Name: t_log_entries trig_t_log_entries_after_update; Type: TRIGGER; Schema: mc; Owner: d3l243
--

CREATE TRIGGER trig_t_log_entries_after_update AFTER UPDATE ON mc.t_log_entries FOR EACH ROW WHEN (((old.posting_time <> new.posting_time) OR (old.posted_by IS DISTINCT FROM new.posted_by) OR (old.type IS DISTINCT FROM new.type) OR (old.message IS DISTINCT FROM new.message))) EXECUTE FUNCTION mc.trigfn_t_log_entries_user_after_update();

--
-- Name: TABLE t_log_entries; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.t_log_entries TO readaccess;
GRANT INSERT ON TABLE mc.t_log_entries TO writeaccess;

