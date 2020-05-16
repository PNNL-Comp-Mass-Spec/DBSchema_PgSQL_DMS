--
-- Name: sproc_stats; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.sproc_stats (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.sproc_stats OWNER TO pgwatch2;

--
-- Name: TABLE sproc_stats; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.sproc_stats IS 'pgwatch2-generated-metric-lvl';

