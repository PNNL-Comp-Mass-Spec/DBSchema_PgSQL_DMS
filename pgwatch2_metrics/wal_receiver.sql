--
-- Name: wal_receiver; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.wal_receiver (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.wal_receiver OWNER TO pgwatch2;

--
-- Name: TABLE wal_receiver; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.wal_receiver IS 'pgwatch2-generated-metric-lvl';

--
-- Name: wal_receiver_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX wal_receiver_dbname_tag_data_time_idx ON ONLY public.wal_receiver USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: wal_receiver_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX wal_receiver_dbname_time_idx ON ONLY public.wal_receiver USING btree (dbname, "time");

