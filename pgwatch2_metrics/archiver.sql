--
-- Name: archiver; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.archiver (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.archiver OWNER TO pgwatch2;

--
-- Name: TABLE archiver; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.archiver IS 'pgwatch2-generated-metric-lvl';

--
-- Name: archiver_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX archiver_dbname_tag_data_time_idx ON ONLY public.archiver USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: archiver_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX archiver_dbname_time_idx ON ONLY public.archiver USING btree (dbname, "time");

