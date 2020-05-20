--
-- Name: replication_slots; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.replication_slots (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.replication_slots OWNER TO pgwatch2;

--
-- Name: TABLE replication_slots; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.replication_slots IS 'pgwatch2-generated-metric-lvl';

--
-- Name: replication_slots_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX replication_slots_dbname_tag_data_time_idx ON ONLY public.replication_slots USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: replication_slots_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX replication_slots_dbname_time_idx ON ONLY public.replication_slots USING btree (dbname, "time");

