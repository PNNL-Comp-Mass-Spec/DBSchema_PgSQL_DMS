--
-- Name: settings; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.settings (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.settings OWNER TO pgwatch2;

--
-- Name: TABLE settings; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.settings IS 'pgwatch2-generated-metric-lvl';

--
-- Name: settings_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX settings_dbname_tag_data_time_idx ON ONLY public.settings USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: settings_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX settings_dbname_time_idx ON ONLY public.settings USING btree (dbname, "time");

