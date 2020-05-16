--
-- Name: wal_receiver; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.wal_receiver (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.wal_receiver OWNER TO pgwatch2;

--
-- Name: TABLE wal_receiver; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.wal_receiver IS 'pgwatch2-generated-metric-lvl';

