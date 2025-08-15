--
-- Name: t_service_cost_rate_burdened; Type: TABLE; Schema: cc; Owner: d3l243
--

CREATE TABLE cc.t_service_cost_rate_burdened (
    cost_group_id integer NOT NULL,
    funding_agency public.citext NOT NULL,
    service_type_id smallint NOT NULL,
    base_rate_per_run real DEFAULT 0.0 NOT NULL,
    pdm real DEFAULT 0.0 NOT NULL,
    general_and_administration real DEFAULT 0.0 NOT NULL,
    safeguards_and_security real DEFAULT 0.0 NOT NULL,
    fee real DEFAULT 0.0 NOT NULL,
    ldrd real DEFAULT 0.0 NOT NULL,
    facilities real DEFAULT 0.0 NOT NULL,
    total_burdened_rate_per_run real GENERATED ALWAYS AS (((((((((base_rate_per_run + pdm) + general_and_administration) + safeguards_and_security) + fee) + ldrd) + facilities))::numeric(1000,2))::real) STORED NOT NULL
);


ALTER TABLE cc.t_service_cost_rate_burdened OWNER TO d3l243;

--
-- Name: t_service_cost_rate_burdened pk_t_service_cost_rate_burdened; Type: CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_cost_rate_burdened
    ADD CONSTRAINT pk_t_service_cost_rate_burdened PRIMARY KEY (cost_group_id, funding_agency, service_type_id);

ALTER TABLE cc.t_service_cost_rate_burdened CLUSTER ON pk_t_service_cost_rate_burdened;

--
-- Name: t_service_cost_rate_burdened fk_pk_t_service_cost_rate_burdened_t_service_cost_group; Type: FK CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_cost_rate_burdened
    ADD CONSTRAINT fk_pk_t_service_cost_rate_burdened_t_service_cost_group FOREIGN KEY (cost_group_id) REFERENCES cc.t_service_cost_group(cost_group_id);

--
-- Name: t_service_cost_rate_burdened fk_pk_t_service_cost_rate_burdened_t_service_type; Type: FK CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_cost_rate_burdened
    ADD CONSTRAINT fk_pk_t_service_cost_rate_burdened_t_service_type FOREIGN KEY (service_type_id) REFERENCES cc.t_service_type(service_type_id) ON UPDATE CASCADE;

--
-- Name: TABLE t_service_cost_rate_burdened; Type: ACL; Schema: cc; Owner: d3l243
--

GRANT SELECT ON TABLE cc.t_service_cost_rate_burdened TO readaccess;
GRANT SELECT ON TABLE cc.t_service_cost_rate_burdened TO writeaccess;

