--
-- Name: backends; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.backends (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.backends OWNER TO pgwatch2;

--
-- Name: TABLE backends; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.backends IS 'pgwatch2-generated-metric-lvl';

