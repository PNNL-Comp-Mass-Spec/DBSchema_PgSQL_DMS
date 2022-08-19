--
-- Name: t_processor_tool_groups; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_processor_tool_groups (
    group_id integer NOT NULL,
    group_name public.citext NOT NULL,
    enabled smallint DEFAULT 1 NOT NULL,
    comment public.citext DEFAULT ''::public.citext NOT NULL
);


ALTER TABLE sw.t_processor_tool_groups OWNER TO d3l243;

--
-- Name: t_processor_tool_groups pk_t_processor_tool_groups; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_processor_tool_groups
    ADD CONSTRAINT pk_t_processor_tool_groups PRIMARY KEY (group_id);

--
-- Name: TABLE t_processor_tool_groups; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_processor_tool_groups TO readaccess;

