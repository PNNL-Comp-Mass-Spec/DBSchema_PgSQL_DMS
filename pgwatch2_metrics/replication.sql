--
-- Name: replication; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.replication (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.replication OWNER TO pgwatch2;

--
-- Name: TABLE replication; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.replication IS 'pgwatch2-generated-metric-lvl';

