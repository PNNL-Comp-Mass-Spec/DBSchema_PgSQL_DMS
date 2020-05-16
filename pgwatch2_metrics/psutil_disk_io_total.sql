--
-- Name: psutil_disk_io_total; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.psutil_disk_io_total (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.psutil_disk_io_total OWNER TO pgwatch2;

--
-- Name: TABLE psutil_disk_io_total; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.psutil_disk_io_total IS 'pgwatch2-generated-metric-lvl';

