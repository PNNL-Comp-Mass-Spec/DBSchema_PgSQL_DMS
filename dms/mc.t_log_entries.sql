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
-- Name: TABLE t_log_entries; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.t_log_entries TO readaccess;
