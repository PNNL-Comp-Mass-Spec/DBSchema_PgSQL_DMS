--
-- Name: stat_statements_calls; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.stat_statements_calls (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.stat_statements_calls OWNER TO pgwatch2;

--
-- Name: TABLE stat_statements_calls; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.stat_statements_calls IS 'pgwatch2-generated-metric-lvl';

--
-- Name: stat_statements_calls_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX stat_statements_calls_dbname_tag_data_time_idx ON ONLY public.stat_statements_calls USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: stat_statements_calls_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX stat_statements_calls_dbname_time_idx ON ONLY public.stat_statements_calls USING btree (dbname, "time");

