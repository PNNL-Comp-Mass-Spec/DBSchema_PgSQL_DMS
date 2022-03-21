--
-- Name: instance_up; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.instance_up (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.instance_up OWNER TO pgwatch2;

--
-- Name: TABLE instance_up; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.instance_up IS 'pgwatch2-generated-metric-lvl';

--
-- Name: instance_up_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX instance_up_dbname_tag_data_time_idx ON ONLY public.instance_up USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: instance_up_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX instance_up_dbname_time_idx ON ONLY public.instance_up USING btree (dbname, "time");

