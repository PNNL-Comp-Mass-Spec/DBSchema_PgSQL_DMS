--
-- Name: privilege_changes; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.privilege_changes (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.privilege_changes OWNER TO pgwatch2;

--
-- Name: TABLE privilege_changes; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.privilege_changes IS 'pgwatch2-generated-metric-lvl';

--
-- Name: privilege_changes_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX privilege_changes_dbname_tag_data_time_idx ON ONLY public.privilege_changes USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: privilege_changes_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX privilege_changes_dbname_time_idx ON ONLY public.privilege_changes USING btree (dbname, "time");

