--
-- Name: backup_age_pgbackrest; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.backup_age_pgbackrest (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.backup_age_pgbackrest OWNER TO pgwatch2;

--
-- Name: TABLE backup_age_pgbackrest; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.backup_age_pgbackrest IS 'pgwatch2-generated-metric-lvl';

