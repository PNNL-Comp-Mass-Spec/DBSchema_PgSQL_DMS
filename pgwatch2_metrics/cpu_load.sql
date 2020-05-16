--
-- Name: cpu_load; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.cpu_load (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.cpu_load OWNER TO pgwatch2;

--
-- Name: TABLE cpu_load; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.cpu_load IS 'pgwatch2-generated-metric-lvl';

