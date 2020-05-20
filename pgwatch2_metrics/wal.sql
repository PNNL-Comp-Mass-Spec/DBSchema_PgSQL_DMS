--
-- Name: wal; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.wal (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.wal OWNER TO pgwatch2;

--
-- Name: TABLE wal; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.wal IS 'pgwatch2-generated-metric-lvl';

--
-- Name: wal_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX wal_dbname_tag_data_time_idx ON ONLY public.wal USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: wal_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX wal_dbname_time_idx ON ONLY public.wal USING btree (dbname, "time");

