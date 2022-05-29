--
-- Name: t_machines; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_machines (
    machine public.citext NOT NULL,
    total_cpus smallint DEFAULT 2 NOT NULL,
    cpus_available integer DEFAULT 0 NOT NULL,
    bionet_available character(1) DEFAULT 'N'::bpchar NOT NULL,
    enabled smallint DEFAULT 1 NOT NULL
);


ALTER TABLE cap.t_machines OWNER TO d3l243;

--
-- Name: t_machines pk_t_machines; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_machines
    ADD CONSTRAINT pk_t_machines PRIMARY KEY (machine);

