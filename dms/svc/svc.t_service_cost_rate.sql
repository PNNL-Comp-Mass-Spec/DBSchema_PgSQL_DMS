--
-- Name: t_service_cost_rate; Type: TABLE; Schema: svc; Owner: d3l243
--

CREATE TABLE svc.t_service_cost_rate (
    cost_group_id integer NOT NULL,
    service_type_id smallint NOT NULL,
    indirect_per_run real DEFAULT 0.0 NOT NULL,
    direct_per_run real DEFAULT 0.0 NOT NULL,
    non_labor_per_run real DEFAULT 0.0 NOT NULL,
    base_rate_per_run real GENERATED ALWAYS AS (((((indirect_per_run + direct_per_run) + non_labor_per_run))::numeric(1000,2))::real) STORED NOT NULL,
    doe_burdened_rate_per_run real,
    hhs_burdened_rate_per_run real,
    ldrd_burdened_rate_per_run real
);


ALTER TABLE svc.t_service_cost_rate OWNER TO d3l243;

--
-- Name: TABLE t_service_cost_rate; Type: COMMENT; Schema: svc; Owner: d3l243
--

COMMENT ON TABLE svc.t_service_cost_rate IS 'Column "base_rate_per_run" is computed by adding indirect_per_run, direct_per_run, and non_labor_per_run.

Use the following queries to update the burdened rate per run columns:

UPDATE cc.t_service_cost_rate target
SET doe_burdened_rate_per_run = total_burdened_rate_per_run
FROM cc.t_service_cost_rate_burdened src
WHERE target.cost_group_id = src.cost_group_id AND
      target.service_type_id = src.service_type_id AND
      src.funding_agency=''DOE'';

UPDATE cc.t_service_cost_rate target
SET hhs_burdened_rate_per_run = total_burdened_rate_per_run
FROM cc.t_service_cost_rate_burdened src
WHERE target.cost_group_id = src.cost_group_id AND
      target.service_type_id = src.service_type_id AND
      src.funding_agency=''HHS'';
';

--
-- Name: t_service_cost_rate pk_t_service_cost_rate; Type: CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_cost_rate
    ADD CONSTRAINT pk_t_service_cost_rate PRIMARY KEY (cost_group_id, service_type_id);

ALTER TABLE svc.t_service_cost_rate CLUSTER ON pk_t_service_cost_rate;

--
-- Name: t_service_cost_rate trig_t_service_cost_rate_before_delete; Type: TRIGGER; Schema: svc; Owner: d3l243
--

CREATE TRIGGER trig_t_service_cost_rate_before_delete BEFORE DELETE ON svc.t_service_cost_rate FOR EACH ROW EXECUTE FUNCTION svc.trigfn_t_service_cost_rate_before_delete();

--
-- Name: t_service_cost_rate fk_t_service_cost_rate_t_service_cost_group; Type: FK CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_cost_rate
    ADD CONSTRAINT fk_t_service_cost_rate_t_service_cost_group FOREIGN KEY (cost_group_id) REFERENCES svc.t_service_cost_group(cost_group_id);

--
-- Name: t_service_cost_rate fk_t_service_cost_rate_t_service_type; Type: FK CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_cost_rate
    ADD CONSTRAINT fk_t_service_cost_rate_t_service_type FOREIGN KEY (service_type_id) REFERENCES svc.t_service_type(service_type_id) ON UPDATE CASCADE;

--
-- Name: TABLE t_service_cost_rate; Type: ACL; Schema: svc; Owner: d3l243
--

GRANT SELECT ON TABLE svc.t_service_cost_rate TO readaccess;
GRANT SELECT ON TABLE svc.t_service_cost_rate TO writeaccess;

