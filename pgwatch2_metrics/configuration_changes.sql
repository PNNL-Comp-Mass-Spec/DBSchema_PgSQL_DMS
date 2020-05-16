--
-- Name: configuration_changes; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.configuration_changes (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.configuration_changes OWNER TO pgwatch2;

--
-- Name: TABLE configuration_changes; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.configuration_changes IS 'pgwatch2-generated-metric-lvl';

