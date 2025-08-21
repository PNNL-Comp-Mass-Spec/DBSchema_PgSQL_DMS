--
-- Name: t_service_cost_group_state; Type: TABLE; Schema: svc; Owner: d3l243
--

CREATE TABLE svc.t_service_cost_group_state (
    service_cost_state_id smallint NOT NULL,
    service_cost_state public.citext NOT NULL
);


ALTER TABLE svc.t_service_cost_group_state OWNER TO d3l243;

--
-- Name: t_service_cost_group_state_service_cost_state_id_seq; Type: SEQUENCE; Schema: svc; Owner: d3l243
--

ALTER TABLE svc.t_service_cost_group_state ALTER COLUMN service_cost_state_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME svc.t_service_cost_group_state_service_cost_state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_service_cost_group_state pk_t_service_cost_group_state; Type: CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_cost_group_state
    ADD CONSTRAINT pk_t_service_cost_group_state PRIMARY KEY (service_cost_state_id);

ALTER TABLE svc.t_service_cost_group_state CLUSTER ON pk_t_service_cost_group_state;

--
-- Name: ix_t_service_cost_group_state_service_cost_state; Type: INDEX; Schema: svc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_service_cost_group_state_service_cost_state ON svc.t_service_cost_group_state USING btree (service_cost_state);

--
-- Name: TABLE t_service_cost_group_state; Type: ACL; Schema: svc; Owner: d3l243
--

GRANT SELECT ON TABLE svc.t_service_cost_group_state TO readaccess;
GRANT SELECT ON TABLE svc.t_service_cost_group_state TO writeaccess;

