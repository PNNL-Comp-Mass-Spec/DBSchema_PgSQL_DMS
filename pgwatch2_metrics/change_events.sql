--
-- Name: change_events; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.change_events (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.change_events OWNER TO pgwatch2;

--
-- Name: TABLE change_events; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.change_events IS 'pgwatch2-generated-metric-lvl';

--
-- Name: change_events_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX change_events_dbname_tag_data_time_idx ON ONLY public.change_events USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: change_events_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX change_events_dbname_time_idx ON ONLY public.change_events USING btree (dbname, "time");

