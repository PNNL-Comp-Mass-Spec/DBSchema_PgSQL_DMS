--
-- Name: t_machine_status_history; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_machine_status_history (
    entry_id integer NOT NULL,
    posting_time timestamp without time zone NOT NULL,
    machine public.citext NOT NULL,
    processor_count_active integer,
    free_memory_mb integer
);


ALTER TABLE sw.t_machine_status_history OWNER TO d3l243;

--
-- Name: t_machine_status_history_entry_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_machine_status_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_machine_status_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_machine_status_history pk_t_machine_status_history; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_machine_status_history
    ADD CONSTRAINT pk_t_machine_status_history PRIMARY KEY (entry_id);

--
-- Name: ix_t_machine_status_history; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_machine_status_history ON sw.t_machine_status_history USING btree (machine);

--
-- Name: TABLE t_machine_status_history; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_machine_status_history TO readaccess;
GRANT SELECT ON TABLE sw.t_machine_status_history TO writeaccess;

