--
-- Name: stat_statements_calls; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.stat_statements_calls (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.stat_statements_calls OWNER TO pgwatch2;

--
-- Name: TABLE stat_statements_calls; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.stat_statements_calls IS 'pgwatch2-generated-metric-lvl';

