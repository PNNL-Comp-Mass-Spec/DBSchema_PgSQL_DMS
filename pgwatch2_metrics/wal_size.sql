--
-- Name: wal_size; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.wal_size (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.wal_size OWNER TO pgwatch2;

--
-- Name: TABLE wal_size; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.wal_size IS 'pgwatch2-generated-metric-lvl';

