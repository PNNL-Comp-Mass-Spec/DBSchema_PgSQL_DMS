--
-- Name: db_size; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.db_size (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.db_size OWNER TO pgwatch2;

--
-- Name: TABLE db_size; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.db_size IS 'pgwatch2-generated-metric-lvl';

