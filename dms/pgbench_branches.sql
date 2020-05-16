--
-- Name: pgbench_branches; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.pgbench_branches (
    bid integer NOT NULL,
    bbalance integer,
    filler character(88)
)
WITH (fillfactor='100');


ALTER TABLE public.pgbench_branches OWNER TO d3l243;

--
-- Name: pgbench_branches pgbench_branches_pkey; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.pgbench_branches
    ADD CONSTRAINT pgbench_branches_pkey PRIMARY KEY (bid);

--
-- Name: TABLE pgbench_branches; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.pgbench_branches TO readaccess;

