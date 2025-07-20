--
-- Name: t_service_cost_rate; Type: TABLE; Schema: cc; Owner: d3l243
--

CREATE TABLE cc.t_service_cost_rate (
    cost_group_id integer NOT NULL,
    service_type_id smallint NOT NULL,
    adjustment real DEFAULT 1.0 NOT NULL,
    base_rate_per_hour_adj real DEFAULT 0.0 NOT NULL,
    overhead_hours_per_run real DEFAULT 1.0 NOT NULL,
    base_rate_per_run real GENERATED ALWAYS AS ((base_rate_per_hour_adj * overhead_hours_per_run)) STORED NOT NULL,
    labor_rate_per_hour real DEFAULT 200 NOT NULL,
    labor_hours_per_run real DEFAULT 0.15 NOT NULL,
    labor_rate_per_run real GENERATED ALWAYS AS ((labor_rate_per_hour * labor_hours_per_run)) STORED NOT NULL
);


ALTER TABLE cc.t_service_cost_rate OWNER TO d3l243;

--
-- Name: TABLE t_service_cost_rate; Type: COMMENT; Schema: cc; Owner: d3l243
--

COMMENT ON TABLE cc.t_service_cost_rate IS 'Column "base_rate_per_hour_adj" is computed by multiplying "base_rate_per_hour" (table cc.t_service_cost_group) and "adjustment" in this table. Column "labor_rate_per_run" should have the same value as "labor_rate_per_hour" in table cc.t_service_cost_group.';

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
    ADD CONSTRAINT fk_t_service_cost_rate_t_service_type FOREIGN KEY (service_type_id) REFERENCES cc.t_service_type(service_type_id);

