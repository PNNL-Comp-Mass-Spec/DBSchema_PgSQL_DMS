--
-- Name: pgbench_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.pgbench_history (
    tid integer,
    bid integer,
    aid integer,
    delta integer,
    mtime timestamp without time zone,
    filler character(22)
);


ALTER TABLE public.pgbench_history OWNER TO d3l243;

