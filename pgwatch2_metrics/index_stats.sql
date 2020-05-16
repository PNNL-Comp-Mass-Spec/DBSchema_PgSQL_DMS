--
-- Name: index_stats; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.index_stats (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.index_stats OWNER TO pgwatch2;

--
-- Name: TABLE index_stats; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.index_stats IS 'pgwatch2-generated-metric-lvl';

