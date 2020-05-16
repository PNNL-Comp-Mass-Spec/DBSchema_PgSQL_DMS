--
-- Name: change_events; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.change_events (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.change_events OWNER TO pgwatch2;

--
-- Name: TABLE change_events; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.change_events IS 'pgwatch2-generated-metric-lvl';

