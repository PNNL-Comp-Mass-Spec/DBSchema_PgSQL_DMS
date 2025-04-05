--
-- Name: t_scripts_history; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_scripts_history (
    entry_id integer NOT NULL,
    script_id integer NOT NULL,
    script public.citext NOT NULL,
    results_tag public.citext,
    contents xml,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER NOT NULL
);


ALTER TABLE cap.t_scripts_history OWNER TO d3l243;

--
-- Name: t_scripts_history_entry_id_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_scripts_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_scripts_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_scripts_history pk_t_scripts_history; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_scripts_history
    ADD CONSTRAINT pk_t_scripts_history PRIMARY KEY (entry_id);

ALTER TABLE cap.t_scripts_history CLUSTER ON pk_t_scripts_history;

--
-- Name: TABLE t_scripts_history; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_scripts_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_scripts_history TO writeaccess;

