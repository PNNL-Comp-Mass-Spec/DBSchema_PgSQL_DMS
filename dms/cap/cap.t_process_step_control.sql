--
-- Name: t_process_step_control; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_process_step_control (
    processing_step_name public.citext NOT NULL,
    enabled integer DEFAULT 0 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE cap.t_process_step_control OWNER TO d3l243;

--
-- Name: t_process_step_control pk_t_process_step_control; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_process_step_control
    ADD CONSTRAINT pk_t_process_step_control PRIMARY KEY (processing_step_name);

--
-- Name: t_process_step_control trig_t_process_step_control_after_update; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_process_step_control_after_update AFTER UPDATE ON cap.t_process_step_control FOR EACH ROW WHEN ((new.enabled <> old.enabled)) EXECUTE FUNCTION cap.trigfn_t_process_step_control_after_update();

--
-- Name: TABLE t_process_step_control; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_process_step_control TO readaccess;

