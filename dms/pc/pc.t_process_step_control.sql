--
-- Name: t_process_step_control; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_process_step_control (
    processing_step_name public.citext NOT NULL,
    enabled integer DEFAULT 0 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE pc.t_process_step_control OWNER TO d3l243;

--
-- Name: t_process_step_control pk_t_process_step_control; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_process_step_control
    ADD CONSTRAINT pk_t_process_step_control PRIMARY KEY (processing_step_name);

--
-- Name: t_process_step_control trig_t_process_step_control_after_update; Type: TRIGGER; Schema: pc; Owner: d3l243
--

CREATE TRIGGER trig_t_process_step_control_after_update AFTER UPDATE ON pc.t_process_step_control FOR EACH ROW WHEN ((new.enabled <> old.enabled)) EXECUTE FUNCTION pc.trigfn_t_process_step_control_after_update();

--
-- Name: TABLE t_process_step_control; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_process_step_control TO readaccess;
GRANT SELECT ON TABLE pc.t_process_step_control TO writeaccess;

