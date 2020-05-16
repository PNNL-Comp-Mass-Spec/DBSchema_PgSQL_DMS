--
-- Name: server_log_event_counts; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.server_log_event_counts (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.server_log_event_counts OWNER TO pgwatch2;

--
-- Name: TABLE server_log_event_counts; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.server_log_event_counts IS 'pgwatch2-generated-metric-lvl';

