--
-- Name: t_service_type; Type: TABLE; Schema: svc; Owner: d3l243
--

CREATE TABLE svc.t_service_type (
    service_type_id smallint NOT NULL,
    service_type public.citext NOT NULL,
    service_description public.citext DEFAULT ''::public.citext NOT NULL,
    abbreviation public.citext DEFAULT ''::public.citext NOT NULL
);


ALTER TABLE svc.t_service_type OWNER TO d3l243;

--
-- Name: t_service_type pk_t_service_type; Type: CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_type
    ADD CONSTRAINT pk_t_service_type PRIMARY KEY (service_type_id);

ALTER TABLE svc.t_service_type CLUSTER ON pk_t_service_type;

--
-- Name: ix_t_service_type_service_type; Type: INDEX; Schema: svc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_service_type_service_type ON svc.t_service_type USING btree (service_type);

--
-- Name: TABLE t_service_type; Type: ACL; Schema: svc; Owner: d3l243
--

GRANT SELECT ON TABLE svc.t_service_type TO readaccess;
GRANT SELECT ON TABLE svc.t_service_type TO writeaccess;

