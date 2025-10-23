--
-- Name: t_machines; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_machines (
    machine public.citext NOT NULL,
    total_cpus smallint DEFAULT 2 NOT NULL,
    cpus_available integer DEFAULT 0 NOT NULL,
    total_memory_mb integer DEFAULT 4000 NOT NULL,
    memory_available integer DEFAULT 4000 NOT NULL,
    proc_tool_group_id integer DEFAULT 0 NOT NULL,
    comment public.citext,
    enabled smallint DEFAULT 1 NOT NULL,
    bionet_only boolean DEFAULT false NOT NULL
);


ALTER TABLE sw.t_machines OWNER TO d3l243;

--
-- Name: t_machines pk_t_machines; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_machines
    ADD CONSTRAINT pk_t_machines PRIMARY KEY (machine);

ALTER TABLE sw.t_machines CLUSTER ON pk_t_machines;

--
-- Name: t_machines fk_t_machines_t_processor_tool_groups; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_machines
    ADD CONSTRAINT fk_t_machines_t_processor_tool_groups FOREIGN KEY (proc_tool_group_id) REFERENCES sw.t_processor_tool_groups(group_id) ON UPDATE CASCADE;

--
-- Name: TABLE t_machines; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_machines TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_machines TO writeaccess;

