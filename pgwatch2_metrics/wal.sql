--
-- Name: wal; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.wal (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.wal OWNER TO pgwatch2;

--
-- Name: TABLE wal; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.wal IS 'pgwatch2-generated-metric-lvl';

