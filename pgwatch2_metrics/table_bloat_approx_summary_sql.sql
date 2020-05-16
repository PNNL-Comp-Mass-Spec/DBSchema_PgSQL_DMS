--
-- Name: table_bloat_approx_summary_sql; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.table_bloat_approx_summary_sql (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.table_bloat_approx_summary_sql OWNER TO pgwatch2;

--
-- Name: TABLE table_bloat_approx_summary_sql; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.table_bloat_approx_summary_sql IS 'pgwatch2-generated-metric-lvl';

