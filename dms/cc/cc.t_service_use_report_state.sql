--
-- Name: t_service_use_report_state; Type: TABLE; Schema: cc; Owner: d3l243
--

CREATE TABLE cc.t_service_use_report_state (
    report_state_id smallint NOT NULL,
    report_state public.citext NOT NULL
);


ALTER TABLE cc.t_service_use_report_state OWNER TO d3l243;

--
-- Name: t_service_use_report_state_report_state_id_seq; Type: SEQUENCE; Schema: cc; Owner: d3l243
--

ALTER TABLE cc.t_service_use_report_state ALTER COLUMN report_state_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cc.t_service_use_report_state_report_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_service_use_report_state pk_t_service_use_report_state; Type: CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_use_report_state
    ADD CONSTRAINT pk_t_service_use_report_state PRIMARY KEY (report_state_id);

ALTER TABLE cc.t_service_use_report_state CLUSTER ON pk_t_service_use_report_state;

--
-- Name: ix_t_service_use_report_state_report_state; Type: INDEX; Schema: cc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_service_use_report_state_report_state ON cc.t_service_use_report_state USING btree (report_state);

--
-- Name: TABLE t_service_use_report_state; Type: ACL; Schema: cc; Owner: d3l243
--

GRANT SELECT ON TABLE cc.t_service_use_report_state TO readaccess;
GRANT SELECT ON TABLE cc.t_service_use_report_state TO writeaccess;

