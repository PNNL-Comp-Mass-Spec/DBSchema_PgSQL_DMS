--
-- Name: recommendations; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.recommendations (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.recommendations OWNER TO pgwatch2;

--
-- Name: TABLE recommendations; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.recommendations IS 'pgwatch2-generated-metric-lvl';

--
-- Name: recommendations_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX recommendations_dbname_tag_data_time_idx ON ONLY public.recommendations USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: recommendations_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX recommendations_dbname_time_idx ON ONLY public.recommendations USING btree (dbname, "time");

