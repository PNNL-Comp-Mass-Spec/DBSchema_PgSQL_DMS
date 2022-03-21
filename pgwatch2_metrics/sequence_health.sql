--
-- Name: sequence_health; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.sequence_health (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.sequence_health OWNER TO pgwatch2;

--
-- Name: TABLE sequence_health; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.sequence_health IS 'pgwatch2-generated-metric-lvl';

--
-- Name: sequence_health_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX sequence_health_dbname_tag_data_time_idx ON ONLY public.sequence_health USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: sequence_health_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX sequence_health_dbname_time_idx ON ONLY public.sequence_health USING btree (dbname, "time");

