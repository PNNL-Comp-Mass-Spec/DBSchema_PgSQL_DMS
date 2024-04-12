--
-- Name: t_step_tools; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_step_tools (
    step_tool_id integer NOT NULL,
    step_tool public.citext NOT NULL,
    type public.citext,
    description public.citext,
    shared_result_version smallint DEFAULT 0 NOT NULL,
    filter_version smallint DEFAULT 0 NOT NULL,
    cpu_load smallint DEFAULT 1 NOT NULL,
    uses_all_cores smallint DEFAULT 0 NOT NULL,
    memory_usage_mb integer DEFAULT 250 NOT NULL,
    parameter_template xml,
    available_for_general_processing public.citext DEFAULT 'Y'::bpchar NOT NULL,
    param_file_storage_path public.citext DEFAULT ''::public.citext,
    comment public.citext DEFAULT ''::public.citext,
    tag public.citext,
    avg_runtime_minutes real,
    disable_output_folder_name_override_on_skip smallint DEFAULT 0 NOT NULL,
    primary_step_tool smallint DEFAULT 0 NOT NULL,
    holdoff_interval_minutes integer DEFAULT 5 NOT NULL
);


ALTER TABLE sw.t_step_tools OWNER TO d3l243;

--
-- Name: t_step_tools_step_tool_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_step_tools ALTER COLUMN step_tool_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_step_tools_step_tool_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_step_tools pk_t_step_tools_1; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_step_tools
    ADD CONSTRAINT pk_t_step_tools_1 PRIMARY KEY (step_tool_id);

--
-- Name: ix_t_step_tools_shared_result_version; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_step_tools_shared_result_version ON sw.t_step_tools USING btree (shared_result_version) INCLUDE (step_tool, disable_output_folder_name_override_on_skip);

--
-- Name: ix_t_step_tools_step_tool; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_step_tools_step_tool ON sw.t_step_tools USING btree (step_tool);

--
-- Name: TABLE t_step_tools; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_step_tools TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_step_tools TO writeaccess;

