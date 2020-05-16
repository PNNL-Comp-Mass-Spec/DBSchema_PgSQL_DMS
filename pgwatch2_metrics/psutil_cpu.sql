--
-- Name: psutil_cpu; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.psutil_cpu (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.psutil_cpu OWNER TO pgwatch2;

--
-- Name: TABLE psutil_cpu; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.psutil_cpu IS 'pgwatch2-generated-metric-lvl';

