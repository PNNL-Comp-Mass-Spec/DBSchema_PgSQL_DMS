--
-- Name: locks_mode; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.locks_mode (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.locks_mode OWNER TO pgwatch2;

--
-- Name: TABLE locks_mode; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.locks_mode IS 'pgwatch2-generated-metric-lvl';

