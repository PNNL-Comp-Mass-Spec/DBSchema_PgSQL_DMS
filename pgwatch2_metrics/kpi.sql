--
-- Name: kpi; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.kpi (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.kpi OWNER TO pgwatch2;

--
-- Name: TABLE kpi; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.kpi IS 'pgwatch2-generated-metric-lvl';

