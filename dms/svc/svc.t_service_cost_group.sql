--
-- Name: t_service_cost_group; Type: TABLE; Schema: svc; Owner: d3l243
--

CREATE TABLE svc.t_service_cost_group (
    cost_group_id integer NOT NULL,
    description public.citext DEFAULT ''::public.citext NOT NULL,
    service_cost_state_id smallint DEFAULT 1 NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE svc.t_service_cost_group OWNER TO d3l243;

--
-- Name: t_service_cost_group_cost_group_id_seq; Type: SEQUENCE; Schema: svc; Owner: d3l243
--

ALTER TABLE svc.t_service_cost_group ALTER COLUMN cost_group_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME svc.t_service_cost_group_cost_group_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_service_cost_group pk_t_service_cost_group; Type: CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_cost_group
    ADD CONSTRAINT pk_t_service_cost_group PRIMARY KEY (cost_group_id);

ALTER TABLE svc.t_service_cost_group CLUSTER ON pk_t_service_cost_group;

--
-- Name: t_service_cost_group fk_t_service_cost_group_t_service_cost_group_state; Type: FK CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_cost_group
    ADD CONSTRAINT fk_t_service_cost_group_t_service_cost_group_state FOREIGN KEY (service_cost_state_id) REFERENCES svc.t_service_cost_group_state(service_cost_state_id);

--
-- Name: TABLE t_service_cost_group; Type: ACL; Schema: svc; Owner: d3l243
--

GRANT SELECT ON TABLE svc.t_service_cost_group TO readaccess;
GRANT SELECT ON TABLE svc.t_service_cost_group TO writeaccess;

