--
-- Name: t_processor_tool_group_details; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_processor_tool_group_details (
    group_id integer NOT NULL,
    mgr_id integer NOT NULL,
    tool_name public.citext NOT NULL,
    priority smallint NOT NULL,
    enabled smallint NOT NULL,
    comment public.citext DEFAULT ''::public.citext NOT NULL,
    max_step_cost smallint DEFAULT 100 NOT NULL,
    max_job_priority smallint DEFAULT 50 NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE sw.t_processor_tool_group_details OWNER TO d3l243;

--
-- Name: t_processor_tool_group_details pk_t_processor_tool_group_details; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_processor_tool_group_details
    ADD CONSTRAINT pk_t_processor_tool_group_details PRIMARY KEY (group_id, mgr_id, tool_name);

ALTER TABLE sw.t_processor_tool_group_details CLUSTER ON pk_t_processor_tool_group_details;

--
-- Name: t_processor_tool_group_details trig_t_processor_tool_group_details_after_update; Type: TRIGGER; Schema: sw; Owner: d3l243
--

CREATE TRIGGER trig_t_processor_tool_group_details_after_update AFTER UPDATE ON sw.t_processor_tool_group_details FOR EACH ROW WHEN (((old.enabled <> new.enabled) OR (old.priority <> new.priority))) EXECUTE FUNCTION sw.trigfn_t_processor_tool_group_details_after_update();

--
-- Name: t_processor_tool_group_details fk_t_processor_tool_group_details_t_processor_tool_groups; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_processor_tool_group_details
    ADD CONSTRAINT fk_t_processor_tool_group_details_t_processor_tool_groups FOREIGN KEY (group_id) REFERENCES sw.t_processor_tool_groups(group_id);

--
-- Name: t_processor_tool_group_details fk_t_processor_tool_group_details_t_step_tools; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_processor_tool_group_details
    ADD CONSTRAINT fk_t_processor_tool_group_details_t_step_tools FOREIGN KEY (tool_name) REFERENCES sw.t_step_tools(step_tool) ON UPDATE CASCADE;

--
-- Name: TABLE t_processor_tool_group_details; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_processor_tool_group_details TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_processor_tool_group_details TO writeaccess;

