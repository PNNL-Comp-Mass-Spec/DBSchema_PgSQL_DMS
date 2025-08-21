--
-- Name: t_service_cost_group; Type: TABLE; Schema: cc; Owner: d3l243
--

CREATE TABLE cc.t_service_cost_group (
    cost_group_id integer NOT NULL,
    description public.citext DEFAULT ''::public.citext NOT NULL,
    service_cost_state_id smallint DEFAULT 1 NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE cc.t_service_cost_group OWNER TO d3l243;

--
-- Name: t_service_cost_group_cost_group_id_seq; Type: SEQUENCE; Schema: cc; Owner: d3l243
--

ALTER TABLE cc.t_service_cost_group ALTER COLUMN cost_group_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cc.t_service_cost_group_cost_group_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_service_cost_group pk_t_service_cost_group; Type: CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_cost_group
    ADD CONSTRAINT pk_t_service_cost_group PRIMARY KEY (cost_group_id);

ALTER TABLE cc.t_service_cost_group CLUSTER ON pk_t_service_cost_group;

--
-- Name: t_service_cost_group fk_t_service_cost_group_t_service_cost_group_state; Type: FK CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_cost_group
    ADD CONSTRAINT fk_t_service_cost_group_t_service_cost_group_state FOREIGN KEY (service_cost_state_id) REFERENCES cc.t_service_cost_group_state(service_cost_state_id);

--
-- Name: TABLE t_service_cost_group; Type: ACL; Schema: cc; Owner: d3l243
--

GRANT SELECT ON TABLE cc.t_service_cost_group TO readaccess;
GRANT SELECT ON TABLE cc.t_service_cost_group TO writeaccess;

