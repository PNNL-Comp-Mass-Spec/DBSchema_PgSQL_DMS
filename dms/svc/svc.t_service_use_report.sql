--
-- Name: t_service_use_report; Type: TABLE; Schema: svc; Owner: d3l243
--

CREATE TABLE svc.t_service_use_report (
    report_id integer NOT NULL,
    start_time timestamp without time zone DEFAULT '2025-01-03 00:00:00'::timestamp without time zone NOT NULL,
    end_time timestamp without time zone DEFAULT '2025-01-09 23:59:59.999'::timestamp without time zone NOT NULL,
    requestor_employee_id public.citext DEFAULT ''::public.citext NOT NULL,
    report_state_id integer DEFAULT 1 NOT NULL,
    cost_group_id integer NOT NULL
);


ALTER TABLE svc.t_service_use_report OWNER TO d3l243;

--
-- Name: t_service_use_report_report_id_seq; Type: SEQUENCE; Schema: svc; Owner: d3l243
--

ALTER TABLE svc.t_service_use_report ALTER COLUMN report_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME svc.t_service_use_report_report_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_service_use_report pk_t_service_use_report; Type: CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_use_report
    ADD CONSTRAINT pk_t_service_use_report PRIMARY KEY (report_id);

ALTER TABLE svc.t_service_use_report CLUSTER ON pk_t_service_use_report;

--
-- Name: t_service_use_report fk_t_service_use_report_t_service_cost_group; Type: FK CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_use_report
    ADD CONSTRAINT fk_t_service_use_report_t_service_cost_group FOREIGN KEY (cost_group_id) REFERENCES svc.t_service_cost_group(cost_group_id);

--
-- Name: t_service_use_report fk_t_service_use_report_t_service_use_report_state; Type: FK CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_use_report
    ADD CONSTRAINT fk_t_service_use_report_t_service_use_report_state FOREIGN KEY (report_state_id) REFERENCES svc.t_service_use_report_state(report_state_id);

--
-- Name: TABLE t_service_use_report; Type: ACL; Schema: svc; Owner: d3l243
--

GRANT SELECT ON TABLE svc.t_service_use_report TO readaccess;
GRANT SELECT,INSERT,UPDATE ON TABLE svc.t_service_use_report TO writeaccess;

