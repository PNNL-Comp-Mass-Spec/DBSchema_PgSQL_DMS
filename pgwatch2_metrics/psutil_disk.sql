--
-- Name: psutil_disk; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.psutil_disk (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.psutil_disk OWNER TO pgwatch2;

--
-- Name: TABLE psutil_disk; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.psutil_disk IS 'pgwatch2-generated-metric-lvl';

--
-- Name: psutil_disk_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX psutil_disk_dbname_tag_data_time_idx ON ONLY public.psutil_disk USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: psutil_disk_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX psutil_disk_dbname_time_idx ON ONLY public.psutil_disk USING btree (dbname, "time");

