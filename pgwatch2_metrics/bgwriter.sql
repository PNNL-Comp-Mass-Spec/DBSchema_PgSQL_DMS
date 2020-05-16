--
-- Name: bgwriter; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.bgwriter (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.bgwriter OWNER TO pgwatch2;

--
-- Name: TABLE bgwriter; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.bgwriter IS 'pgwatch2-generated-metric-lvl';

