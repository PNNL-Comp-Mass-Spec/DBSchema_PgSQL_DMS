--
-- Name: sproc_changes; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.sproc_changes (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.sproc_changes OWNER TO pgwatch2;

--
-- Name: TABLE sproc_changes; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.sproc_changes IS 'pgwatch2-generated-metric-lvl';

--
-- Name: sproc_changes_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX sproc_changes_dbname_tag_data_time_idx ON ONLY public.sproc_changes USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: sproc_changes_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX sproc_changes_dbname_time_idx ON ONLY public.sproc_changes USING btree (dbname, "time");

