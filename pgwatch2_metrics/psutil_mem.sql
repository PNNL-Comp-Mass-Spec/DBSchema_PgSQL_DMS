--
-- Name: psutil_mem; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.psutil_mem (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.psutil_mem OWNER TO pgwatch2;

--
-- Name: TABLE psutil_mem; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.psutil_mem IS 'pgwatch2-generated-metric-lvl';

--
-- Name: psutil_mem_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX psutil_mem_dbname_tag_data_time_idx ON ONLY public.psutil_mem USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: psutil_mem_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX psutil_mem_dbname_time_idx ON ONLY public.psutil_mem USING btree (dbname, "time");

