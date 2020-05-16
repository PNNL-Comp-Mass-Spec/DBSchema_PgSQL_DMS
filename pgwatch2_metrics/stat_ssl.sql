--
-- Name: stat_ssl; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.stat_ssl (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.stat_ssl OWNER TO pgwatch2;

--
-- Name: TABLE stat_ssl; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.stat_ssl IS 'pgwatch2-generated-metric-lvl';

