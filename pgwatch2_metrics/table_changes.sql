--
-- Name: table_changes; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.table_changes (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.table_changes OWNER TO pgwatch2;

--
-- Name: TABLE table_changes; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.table_changes IS 'pgwatch2-generated-metric-lvl';

