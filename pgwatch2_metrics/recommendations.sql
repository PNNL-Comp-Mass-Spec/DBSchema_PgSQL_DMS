--
-- Name: recommendations; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.recommendations (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.recommendations OWNER TO pgwatch2;

--
-- Name: TABLE recommendations; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.recommendations IS 'pgwatch2-generated-metric-lvl';

