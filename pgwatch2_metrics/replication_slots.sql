--
-- Name: replication_slots; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.replication_slots (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.replication_slots OWNER TO pgwatch2;

--
-- Name: TABLE replication_slots; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.replication_slots IS 'pgwatch2-generated-metric-lvl';

