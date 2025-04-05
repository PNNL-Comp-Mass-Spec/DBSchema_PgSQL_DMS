--
-- Name: t_step_tools; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_step_tools (
    step_tool_id integer NOT NULL,
    step_tool public.citext NOT NULL,
    description public.citext,
    bionet_required public.citext DEFAULT 'N'::bpchar NOT NULL,
    only_on_storage_server public.citext DEFAULT 'N'::bpchar NOT NULL,
    instrument_capacity_limited public.citext DEFAULT 'N'::bpchar NOT NULL,
    holdoff_interval_minutes smallint DEFAULT 0 NOT NULL,
    number_of_retries smallint DEFAULT 0 NOT NULL,
    processor_assignment_applies public.citext DEFAULT 'N'::bpchar NOT NULL
);


ALTER TABLE cap.t_step_tools OWNER TO d3l243;

--
-- Name: t_step_tools_step_tool_id_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_step_tools ALTER COLUMN step_tool_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_step_tools_step_tool_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_step_tools pk_t_step_tools; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_step_tools
    ADD CONSTRAINT pk_t_step_tools PRIMARY KEY (step_tool_id);

ALTER TABLE cap.t_step_tools CLUSTER ON pk_t_step_tools;

--
-- Name: ix_t_step_tools_step_tool; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_step_tools_step_tool ON cap.t_step_tools USING btree (step_tool);

--
-- Name: TABLE t_step_tools; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_step_tools TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_step_tools TO writeaccess;

