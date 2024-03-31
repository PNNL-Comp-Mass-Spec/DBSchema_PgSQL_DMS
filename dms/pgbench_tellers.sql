--
-- Name: pgbench_tellers; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.pgbench_tellers (
    tid integer NOT NULL,
    bid integer,
    tbalance integer,
    filler character(84)
)
WITH (fillfactor='100');


ALTER TABLE public.pgbench_tellers OWNER TO d3l243;

--
-- Name: pgbench_tellers pgbench_tellers_pkey; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.pgbench_tellers
    ADD CONSTRAINT pgbench_tellers_pkey PRIMARY KEY (tid);

--
-- Name: TABLE pgbench_tellers; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.pgbench_tellers TO readaccess;
GRANT SELECT ON TABLE public.pgbench_tellers TO writeaccess;

