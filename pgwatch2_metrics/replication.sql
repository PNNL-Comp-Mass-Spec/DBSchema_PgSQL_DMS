--
-- Name: replication; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.replication (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.replication OWNER TO pgwatch2;

--
-- Name: TABLE replication; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.replication IS 'pgwatch2-generated-metric-lvl';

--
-- Name: replication_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX replication_dbname_tag_data_time_idx ON ONLY public.replication USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: replication_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX replication_dbname_time_idx ON ONLY public.replication USING btree (dbname, "time");

