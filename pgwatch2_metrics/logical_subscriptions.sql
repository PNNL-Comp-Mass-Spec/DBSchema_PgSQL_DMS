--
-- Name: logical_subscriptions; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.logical_subscriptions (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.logical_subscriptions OWNER TO pgwatch2;

--
-- Name: TABLE logical_subscriptions; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.logical_subscriptions IS 'pgwatch2-generated-metric-lvl';

--
-- Name: logical_subscriptions_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX logical_subscriptions_dbname_tag_data_time_idx ON ONLY public.logical_subscriptions USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: logical_subscriptions_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX logical_subscriptions_dbname_time_idx ON ONLY public.logical_subscriptions USING btree (dbname, "time");

