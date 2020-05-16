--
-- Name: object_changes; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.object_changes (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.object_changes OWNER TO pgwatch2;

--
-- Name: TABLE object_changes; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.object_changes IS 'pgwatch2-generated-metric-lvl';

