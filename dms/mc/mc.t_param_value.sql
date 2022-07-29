--
-- Name: t_param_value; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_param_value (
    entry_id integer NOT NULL,
    type_id integer NOT NULL,
    value public.citext NOT NULL,
    mgr_id integer NOT NULL,
    comment public.citext,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE mc.t_param_value OWNER TO d3l243;

--
-- Name: t_param_value_entry_id_seq; Type: SEQUENCE; Schema: mc; Owner: d3l243
--

ALTER TABLE mc.t_param_value ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mc.t_param_value_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_param_value pk_t_param_value; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_param_value
    ADD CONSTRAINT pk_t_param_value PRIMARY KEY (entry_id);

--
-- Name: ix_t_param_value; Type: INDEX; Schema: mc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_param_value ON mc.t_param_value USING btree (mgr_id, type_id);

--
-- Name: ix_t_param_value_type_id_include_entry_id_mgr_id; Type: INDEX; Schema: mc; Owner: d3l243
--

CREATE INDEX ix_t_param_value_type_id_include_entry_id_mgr_id ON mc.t_param_value USING btree (type_id) INCLUDE (entry_id, mgr_id);

--
-- Name: t_param_value trig_t_param_value_after_delete; Type: TRIGGER; Schema: mc; Owner: d3l243
--

CREATE TRIGGER trig_t_param_value_after_delete AFTER DELETE ON mc.t_param_value REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION mc.trigfn_t_param_value_after_delete();

--
-- Name: t_param_value trig_t_param_value_after_insert; Type: TRIGGER; Schema: mc; Owner: d3l243
--

CREATE TRIGGER trig_t_param_value_after_insert AFTER INSERT ON mc.t_param_value REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION mc.trigfn_t_param_value_after_insert();

--
-- Name: t_param_value trig_t_param_value_after_update; Type: TRIGGER; Schema: mc; Owner: d3l243
--

CREATE TRIGGER trig_t_param_value_after_update AFTER UPDATE OF type_id, value, mgr_id ON mc.t_param_value FOR EACH ROW EXECUTE FUNCTION mc.trigfn_t_param_value_after_update();

--
-- Name: t_param_value fk_t_param_value_t_mgrs; Type: FK CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_param_value
    ADD CONSTRAINT fk_t_param_value_t_mgrs FOREIGN KEY (mgr_id) REFERENCES mc.t_mgrs(mgr_id) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: t_param_value fk_t_param_value_t_param_type; Type: FK CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_param_value
    ADD CONSTRAINT fk_t_param_value_t_param_type FOREIGN KEY (type_id) REFERENCES mc.t_param_type(param_id) ON UPDATE CASCADE;

--
-- Name: TABLE t_param_value; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.t_param_value TO readaccess;
GRANT INSERT,UPDATE ON TABLE mc.t_param_value TO writeaccess;

