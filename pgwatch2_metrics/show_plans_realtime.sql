--
-- Name: show_plans_realtime; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE UNLOGGED TABLE public.show_plans_realtime (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.show_plans_realtime OWNER TO pgwatch2;

--
-- Name: TABLE show_plans_realtime; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.show_plans_realtime IS 'pgwatch2-generated-metric-lvl';

