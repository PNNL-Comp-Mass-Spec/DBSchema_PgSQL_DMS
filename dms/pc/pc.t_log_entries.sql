--
-- Name: t_log_entries; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_log_entries (
    entry_id integer NOT NULL,
    posted_by public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    type public.citext,
    message public.citext,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE pc.t_log_entries OWNER TO d3l243;

--
-- Name: t_log_entries_entry_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_log_entries ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_log_entries_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_log_entries pk_t_log_entries; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_log_entries
    ADD CONSTRAINT pk_t_log_entries PRIMARY KEY (entry_id);

--
-- Name: t_log_entries trig_t_log_entries_after_update; Type: TRIGGER; Schema: pc; Owner: d3l243
--

CREATE TRIGGER trig_t_log_entries_after_update AFTER UPDATE ON pc.t_log_entries FOR EACH ROW WHEN (((old.entered <> new.entered) OR ((old.posted_by)::text IS DISTINCT FROM (new.posted_by)::text) OR ((old.type)::text IS DISTINCT FROM (new.type)::text) OR ((old.message)::text IS DISTINCT FROM (new.message)::text))) EXECUTE FUNCTION pc.trigfn_t_log_entries_user_after_update();

--
-- Name: TABLE t_log_entries; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_log_entries TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_log_entries TO writeaccess;
GRANT INSERT,UPDATE ON TABLE pc.t_log_entries TO dmswebuser;
GRANT INSERT,DELETE,UPDATE ON TABLE pc.t_log_entries TO pceditor;

