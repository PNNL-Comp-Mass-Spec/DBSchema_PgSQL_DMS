--
-- Name: t_processor_tool; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_processor_tool (
    processor_name public.citext NOT NULL,
    tool_name public.citext NOT NULL,
    priority smallint DEFAULT 3 NOT NULL,
    enabled smallint DEFAULT 1 NOT NULL,
    comment public.citext DEFAULT ''::public.citext NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE cap.t_processor_tool OWNER TO d3l243;

--
-- Name: t_processor_tool pk_t_processor_tool; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_processor_tool
    ADD CONSTRAINT pk_t_processor_tool PRIMARY KEY (processor_name, tool_name);

--
-- Name: t_processor_tool trig_t_processor_tool_after_update; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_processor_tool_after_update AFTER UPDATE ON cap.t_processor_tool FOR EACH ROW WHEN (((new.enabled <> old.enabled) OR (new.priority <> old.priority))) EXECUTE FUNCTION cap.trigfn_t_processor_tool_after_update();

--
-- Name: t_processor_tool fk_t_processor_tool_t_step_tools; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_processor_tool
    ADD CONSTRAINT fk_t_processor_tool_t_step_tools FOREIGN KEY (tool_name) REFERENCES cap.t_step_tools(step_tool);

