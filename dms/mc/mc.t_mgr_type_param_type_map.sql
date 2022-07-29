--
-- Name: t_mgr_type_param_type_map; Type: TABLE; Schema: mc; Owner: d3l243
--

CREATE TABLE mc.t_mgr_type_param_type_map (
    mgr_type_id integer NOT NULL,
    param_type_id integer NOT NULL,
    default_value public.citext,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE mc.t_mgr_type_param_type_map OWNER TO d3l243;

--
-- Name: t_mgr_type_param_type_map pk_t_mgr_type_param_type_map; Type: CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_mgr_type_param_type_map
    ADD CONSTRAINT pk_t_mgr_type_param_type_map PRIMARY KEY (mgr_type_id, param_type_id);

--
-- Name: t_mgr_type_param_type_map trig_t_mgr_type_param_type_map_after_update; Type: TRIGGER; Schema: mc; Owner: d3l243
--

CREATE TRIGGER trig_t_mgr_type_param_type_map_after_update AFTER UPDATE OF mgr_type_id, param_type_id, default_value ON mc.t_mgr_type_param_type_map FOR EACH ROW EXECUTE FUNCTION mc.trigfn_t_mgr_type_param_type_map_after_update();

--
-- Name: t_mgr_type_param_type_map fk_t_mgr_type_param_type_map_t_mgr_types; Type: FK CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_mgr_type_param_type_map
    ADD CONSTRAINT fk_t_mgr_type_param_type_map_t_mgr_types FOREIGN KEY (mgr_type_id) REFERENCES mc.t_mgr_types(mgr_type_id);

--
-- Name: t_mgr_type_param_type_map fk_t_mgr_type_param_type_map_t_param_type; Type: FK CONSTRAINT; Schema: mc; Owner: d3l243
--

ALTER TABLE ONLY mc.t_mgr_type_param_type_map
    ADD CONSTRAINT fk_t_mgr_type_param_type_map_t_param_type FOREIGN KEY (param_type_id) REFERENCES mc.t_param_type(param_id) ON UPDATE CASCADE;

--
-- Name: TABLE t_mgr_type_param_type_map; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.t_mgr_type_param_type_map TO readaccess;

