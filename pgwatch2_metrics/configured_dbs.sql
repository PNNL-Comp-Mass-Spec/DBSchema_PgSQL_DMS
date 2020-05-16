--
-- Name: configured_dbs; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.configured_dbs (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.configured_dbs OWNER TO pgwatch2;

--
-- Name: TABLE configured_dbs; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.configured_dbs IS 'pgwatch2-generated-metric-lvl';

