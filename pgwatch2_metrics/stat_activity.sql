--
-- Name: stat_activity; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.stat_activity (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.stat_activity OWNER TO pgwatch2;

--
-- Name: TABLE stat_activity; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.stat_activity IS 'pgwatch2-generated-metric-lvl';

--
-- Name: stat_activity_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX stat_activity_dbname_tag_data_time_idx ON ONLY public.stat_activity USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: stat_activity_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX stat_activity_dbname_time_idx ON ONLY public.stat_activity USING btree (dbname, "time");

