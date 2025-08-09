--
-- Name: t_service_cost_rate; Type: TABLE; Schema: cc; Owner: d3l243
--

CREATE TABLE cc.t_service_cost_rate (
    cost_group_id integer NOT NULL,
    service_type_id smallint NOT NULL,
    indirect_per_run real DEFAULT 0.0 NOT NULL,
    direct_per_run real DEFAULT 0.0 NOT NULL,
    non_labor_per_run real DEFAULT 0.0 NOT NULL,
    total_per_run real GENERATED ALWAYS AS (((((indirect_per_run + direct_per_run) + non_labor_per_run))::numeric(1000,2))::real) STORED NOT NULL
);


ALTER TABLE cc.t_service_cost_rate OWNER TO d3l243;

--
-- Name: TABLE t_service_cost_rate; Type: COMMENT; Schema: cc; Owner: d3l243
--

COMMENT ON TABLE cc.t_service_cost_rate IS 'Column "total_per_run" is computed by adding indirect_per_run, direct_per_run, and non_labor_per_run';

--
-- Name: t_service_cost_rate pk_t_service_cost_rate; Type: CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_cost_rate
    ADD CONSTRAINT pk_t_service_cost_rate PRIMARY KEY (cost_group_id, service_type_id);

ALTER TABLE cc.t_service_cost_rate CLUSTER ON pk_t_service_cost_rate;

--
-- Name: t_service_cost_rate fk_t_service_cost_rate_t_service_cost_group; Type: FK CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_cost_rate
    ADD CONSTRAINT fk_t_service_cost_rate_t_service_cost_group FOREIGN KEY (cost_group_id) REFERENCES cc.t_service_cost_group(cost_group_id);

--
-- Name: t_service_cost_rate fk_t_service_cost_rate_t_service_type; Type: FK CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_cost_rate
    ADD CONSTRAINT fk_t_service_cost_rate_t_service_type FOREIGN KEY (service_type_id) REFERENCES cc.t_service_type(service_type_id) ON UPDATE CASCADE;

--
-- Name: TABLE t_service_cost_rate; Type: ACL; Schema: cc; Owner: d3l243
--

GRANT SELECT ON TABLE cc.t_service_cost_rate TO readaccess;
GRANT SELECT ON TABLE cc.t_service_cost_rate TO writeaccess;

