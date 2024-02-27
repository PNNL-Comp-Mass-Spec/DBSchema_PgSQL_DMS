--
-- Name: t_event_log; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_event_log (
    event_id integer NOT NULL,
    target_type integer,
    target_id integer,
    target_state smallint,
    prev_target_state smallint,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE pc.t_event_log OWNER TO d3l243;

--
-- Name: t_event_log_event_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_event_log ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_event_log_event_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_event_log pk_t_event_log; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_event_log
    ADD CONSTRAINT pk_t_event_log PRIMARY KEY (event_id);

--
-- Name: ix_t_event_log; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_event_log ON pc.t_event_log USING btree (target_id);

--
-- Name: t_event_log fk_t_event_log_t_event_target; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_event_log
    ADD CONSTRAINT fk_t_event_log_t_event_target FOREIGN KEY (target_type) REFERENCES pc.t_event_target(id);

--
-- Name: TABLE t_event_log; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_event_log TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_event_log TO writeaccess;
GRANT INSERT,UPDATE ON TABLE pc.t_event_log TO dmswebuser;

