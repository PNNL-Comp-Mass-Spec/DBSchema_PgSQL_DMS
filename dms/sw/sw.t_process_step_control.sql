--
-- Name: t_process_step_control; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_process_step_control (
    processing_step_name public.citext NOT NULL,
    enabled integer DEFAULT 0 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE sw.t_process_step_control OWNER TO d3l243;

--
-- Name: t_process_step_control pk_t_process_step_control; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_process_step_control
    ADD CONSTRAINT pk_t_process_step_control PRIMARY KEY (processing_step_name);

--
-- Name: t_process_step_control trig_t_process_step_control_after_update; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_process_step_control_after_update AFTER UPDATE ON sw.t_process_step_control FOR EACH ROW WHEN ((new.enabled <> old.enabled)) EXECUTE FUNCTION sw.trigfn_t_process_step_control_after_update();

--
-- Name: TABLE t_process_step_control; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_process_step_control TO readaccess;
GRANT SELECT ON TABLE sw.t_process_step_control TO writeaccess;

