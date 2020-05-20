--
-- Name: index_changes; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.index_changes (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.index_changes OWNER TO pgwatch2;

--
-- Name: TABLE index_changes; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.index_changes IS 'pgwatch2-generated-metric-lvl';

--
-- Name: index_changes_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX index_changes_dbname_tag_data_time_idx ON ONLY public.index_changes USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: index_changes_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX index_changes_dbname_time_idx ON ONLY public.index_changes USING btree (dbname, "time");

