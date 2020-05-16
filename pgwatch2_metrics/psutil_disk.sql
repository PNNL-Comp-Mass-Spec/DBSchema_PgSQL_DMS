--
-- Name: psutil_disk; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.psutil_disk (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.psutil_disk OWNER TO pgwatch2;

--
-- Name: TABLE psutil_disk; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.psutil_disk IS 'pgwatch2-generated-metric-lvl';

