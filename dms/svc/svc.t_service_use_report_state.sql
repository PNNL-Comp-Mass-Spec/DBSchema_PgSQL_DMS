--
-- Name: t_service_use_report_state; Type: TABLE; Schema: svc; Owner: d3l243
--

CREATE TABLE svc.t_service_use_report_state (
    report_state_id smallint NOT NULL,
    report_state public.citext NOT NULL
);


ALTER TABLE svc.t_service_use_report_state OWNER TO d3l243;

--
-- Name: t_service_use_report_state_report_state_id_seq; Type: SEQUENCE; Schema: svc; Owner: d3l243
--

ALTER TABLE svc.t_service_use_report_state ALTER COLUMN report_state_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME svc.t_service_use_report_state_report_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_service_use_report_state pk_t_service_use_report_state; Type: CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_use_report_state
    ADD CONSTRAINT pk_t_service_use_report_state PRIMARY KEY (report_state_id);

ALTER TABLE svc.t_service_use_report_state CLUSTER ON pk_t_service_use_report_state;

--
-- Name: ix_t_service_use_report_state_report_state; Type: INDEX; Schema: svc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_service_use_report_state_report_state ON svc.t_service_use_report_state USING btree (report_state);

--
-- Name: TABLE t_service_use_report_state; Type: ACL; Schema: svc; Owner: d3l243
--

GRANT SELECT ON TABLE svc.t_service_use_report_state TO readaccess;
GRANT SELECT ON TABLE svc.t_service_use_report_state TO writeaccess;

