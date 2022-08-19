--
-- Name: t_local_processors; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_local_processors (
    processor_name public.citext NOT NULL,
    processor_id integer NOT NULL,
    state character(1) NOT NULL,
    proc_tool_mgr_id smallint DEFAULT 1 NOT NULL,
    groups integer DEFAULT 0,
    gp_groups integer,
    machine public.citext NOT NULL,
    latest_request timestamp without time zone,
    manager_version public.citext,
    work_dir_admin_share public.citext
);


ALTER TABLE sw.t_local_processors OWNER TO d3l243;

--
-- Name: t_local_processors pk_t_local_processors; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_local_processors
    ADD CONSTRAINT pk_t_local_processors PRIMARY KEY (processor_name);

--
-- Name: ix_t_local_processors_machine; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_local_processors_machine ON sw.t_local_processors USING btree (machine);

--
-- Name: ix_t_local_processors_tool_mgr_id_machine_include_proc_name; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_local_processors_tool_mgr_id_machine_include_proc_name ON sw.t_local_processors USING btree (proc_tool_mgr_id, machine) INCLUDE (processor_name);

--
-- Name: TABLE t_local_processors; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_local_processors TO readaccess;

