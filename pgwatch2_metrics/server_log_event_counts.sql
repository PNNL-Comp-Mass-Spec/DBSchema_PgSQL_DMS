--
-- Name: server_log_event_counts; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.server_log_event_counts (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.server_log_event_counts OWNER TO pgwatch2;

--
-- Name: TABLE server_log_event_counts; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.server_log_event_counts IS 'pgwatch2-generated-metric-lvl';

--
-- Name: server_log_event_counts_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX server_log_event_counts_dbname_tag_data_time_idx ON ONLY public.server_log_event_counts USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: server_log_event_counts_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX server_log_event_counts_dbname_time_idx ON ONLY public.server_log_event_counts USING btree (dbname, "time");

