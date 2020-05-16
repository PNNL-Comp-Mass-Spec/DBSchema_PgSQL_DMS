--
-- Name: logical_subscriptions; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.logical_subscriptions (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.logical_subscriptions OWNER TO pgwatch2;

--
-- Name: TABLE logical_subscriptions; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.logical_subscriptions IS 'pgwatch2-generated-metric-lvl';

