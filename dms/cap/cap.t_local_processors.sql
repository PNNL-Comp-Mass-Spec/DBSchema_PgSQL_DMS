--
-- Name: t_local_processors; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_local_processors (
    processor_name public.citext NOT NULL,
    state public.citext DEFAULT 'E'::bpchar NOT NULL,
    machine public.citext NOT NULL,
    latest_request timestamp without time zone,
    manager_version public.citext
);


ALTER TABLE cap.t_local_processors OWNER TO d3l243;

--
-- Name: t_local_processors pk_t_local_processors; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_local_processors
    ADD CONSTRAINT pk_t_local_processors PRIMARY KEY (processor_name);

ALTER TABLE cap.t_local_processors CLUSTER ON pk_t_local_processors;

--
-- Name: t_local_processors fk_t_local_processors_t_machines; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_local_processors
    ADD CONSTRAINT fk_t_local_processors_t_machines FOREIGN KEY (machine) REFERENCES cap.t_machines(machine);

--
-- Name: TABLE t_local_processors; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_local_processors TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_local_processors TO writeaccess;

