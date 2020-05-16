--
-- Name: stat_statements; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.stat_statements (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.stat_statements OWNER TO pgwatch2;

--
-- Name: TABLE stat_statements; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.stat_statements IS 'pgwatch2-generated-metric-lvl';

