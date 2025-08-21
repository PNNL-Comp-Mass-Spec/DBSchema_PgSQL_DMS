--
-- Name: t_service_use_updates; Type: TABLE; Schema: svc; Owner: d3l243
--

CREATE TABLE svc.t_service_use_updates (
    entry_id integer NOT NULL,
    service_use_entry_id integer NOT NULL,
    dataset_id integer NOT NULL,
    charge_code_change public.citext,
    service_type_change text,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE svc.t_service_use_updates OWNER TO d3l243;

--
-- Name: t_service_use_updates_entry_id_seq; Type: SEQUENCE; Schema: svc; Owner: d3l243
--

ALTER TABLE svc.t_service_use_updates ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME svc.t_service_use_updates_entry_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_service_use_updates pk_t_service_use_updates; Type: CONSTRAINT; Schema: svc; Owner: d3l243
--

ALTER TABLE ONLY svc.t_service_use_updates
    ADD CONSTRAINT pk_t_service_use_updates PRIMARY KEY (entry_id);

ALTER TABLE svc.t_service_use_updates CLUSTER ON pk_t_service_use_updates;

--
-- Name: ix_t_service_use_updates_dataset_id; Type: INDEX; Schema: svc; Owner: d3l243
--

CREATE INDEX ix_t_service_use_updates_dataset_id ON svc.t_service_use_updates USING btree (dataset_id);

--
-- Name: ix_t_service_use_updates_entered; Type: INDEX; Schema: svc; Owner: d3l243
--

CREATE INDEX ix_t_service_use_updates_entered ON svc.t_service_use_updates USING btree (entered);

--
-- Name: ix_t_service_use_updates_service_use_entry_id; Type: INDEX; Schema: svc; Owner: d3l243
--

CREATE INDEX ix_t_service_use_updates_service_use_entry_id ON svc.t_service_use_updates USING btree (service_use_entry_id);

--
-- Name: TABLE t_service_use_updates; Type: ACL; Schema: svc; Owner: d3l243
--

GRANT SELECT ON TABLE svc.t_service_use_updates TO readaccess;
GRANT SELECT,INSERT,UPDATE ON TABLE svc.t_service_use_updates TO writeaccess;

