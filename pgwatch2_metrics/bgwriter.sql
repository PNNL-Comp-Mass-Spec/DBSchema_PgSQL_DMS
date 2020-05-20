--
-- Name: bgwriter; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.bgwriter (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.bgwriter OWNER TO pgwatch2;

--
-- Name: TABLE bgwriter; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.bgwriter IS 'pgwatch2-generated-metric-lvl';

--
-- Name: bgwriter_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX bgwriter_dbname_tag_data_time_idx ON ONLY public.bgwriter USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: bgwriter_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX bgwriter_dbname_time_idx ON ONLY public.bgwriter USING btree (dbname, "time");

