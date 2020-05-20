--
-- Name: db_stats; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.db_stats (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.db_stats OWNER TO pgwatch2;

--
-- Name: TABLE db_stats; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.db_stats IS 'pgwatch2-generated-metric-lvl';

--
-- Name: db_stats_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX db_stats_dbname_tag_data_time_idx ON ONLY public.db_stats USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: db_stats_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX db_stats_dbname_time_idx ON ONLY public.db_stats USING btree (dbname, "time");

