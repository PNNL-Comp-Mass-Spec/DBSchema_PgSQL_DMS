--
-- Name: backup_age_pgbackrest; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.backup_age_pgbackrest (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.backup_age_pgbackrest OWNER TO pgwatch2;

--
-- Name: TABLE backup_age_pgbackrest; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.backup_age_pgbackrest IS 'pgwatch2-generated-metric-lvl';

--
-- Name: backup_age_pgbackrest_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX backup_age_pgbackrest_dbname_tag_data_time_idx ON ONLY public.backup_age_pgbackrest USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: backup_age_pgbackrest_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX backup_age_pgbackrest_dbname_time_idx ON ONLY public.backup_age_pgbackrest USING btree (dbname, "time");

