--
-- Name: archiver; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.archiver (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.archiver OWNER TO pgwatch2;

--
-- Name: TABLE archiver; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.archiver IS 'pgwatch2-generated-metric-lvl';

