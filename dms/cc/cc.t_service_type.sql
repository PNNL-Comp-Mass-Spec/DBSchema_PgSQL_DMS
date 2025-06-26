--
-- Name: t_service_type; Type: TABLE; Schema: cc; Owner: d3l243
--

CREATE TABLE cc.t_service_type (
    service_type_id smallint NOT NULL,
    service_type public.citext NOT NULL,
    service_description public.citext DEFAULT ''::public.citext NOT NULL
);


ALTER TABLE cc.t_service_type OWNER TO d3l243;

--
-- Name: t_service_type pk_t_service_type; Type: CONSTRAINT; Schema: cc; Owner: d3l243
--

ALTER TABLE ONLY cc.t_service_type
    ADD CONSTRAINT pk_t_service_type PRIMARY KEY (service_type_id);

ALTER TABLE cc.t_service_type CLUSTER ON pk_t_service_type;

--
-- Name: ix_t_service_type_service_type; Type: INDEX; Schema: cc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_service_type_service_type ON cc.t_service_type USING btree (service_type);

--
-- Name: TABLE t_service_type; Type: ACL; Schema: cc; Owner: d3l243
--

GRANT SELECT ON TABLE cc.t_service_type TO readaccess;
GRANT SELECT ON TABLE cc.t_service_type TO writeaccess;

