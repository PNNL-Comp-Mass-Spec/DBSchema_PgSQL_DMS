--
-- Name: stat_activity_realtime; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE UNLOGGED TABLE public.stat_activity_realtime (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.stat_activity_realtime OWNER TO pgwatch2;

--
-- Name: TABLE stat_activity_realtime; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.stat_activity_realtime IS 'pgwatch2-generated-metric-lvl';

--
-- Name: stat_activity_realtime_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX stat_activity_realtime_dbname_time_idx ON ONLY public.stat_activity_realtime USING btree (dbname, "time");

