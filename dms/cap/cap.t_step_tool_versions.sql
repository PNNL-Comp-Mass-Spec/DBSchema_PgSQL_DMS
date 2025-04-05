--
-- Name: t_step_tool_versions; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_step_tool_versions (
    tool_version_id integer NOT NULL,
    tool_version public.citext NOT NULL,
    most_recent_job integer,
    last_used timestamp without time zone,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE cap.t_step_tool_versions OWNER TO d3l243;

--
-- Name: t_step_tool_versions_tool_version_id_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_step_tool_versions ALTER COLUMN tool_version_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_step_tool_versions_tool_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_step_tool_versions pk_t_step_tool_versions; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_step_tool_versions
    ADD CONSTRAINT pk_t_step_tool_versions PRIMARY KEY (tool_version_id);

ALTER TABLE cap.t_step_tool_versions CLUSTER ON pk_t_step_tool_versions;

--
-- Name: ix_t_step_tool_versions; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_step_tool_versions ON cap.t_step_tool_versions USING btree (tool_version);

--
-- Name: TABLE t_step_tool_versions; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_step_tool_versions TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_step_tool_versions TO writeaccess;

