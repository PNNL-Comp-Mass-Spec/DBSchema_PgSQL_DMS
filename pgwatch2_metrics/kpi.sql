--
-- Name: kpi; Type: TABLE; Schema: public; Owner: pgwatch2
--

CREATE TABLE public.kpi (
    "time" timestamp with time zone NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb
)
PARTITION BY RANGE ("time");


ALTER TABLE public.kpi OWNER TO pgwatch2;

--
-- Name: TABLE kpi; Type: COMMENT; Schema: public; Owner: pgwatch2
--

COMMENT ON TABLE public.kpi IS 'pgwatch2-generated-metric-lvl';

--
-- Name: kpi_dbname_tag_data_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX kpi_dbname_tag_data_time_idx ON ONLY public.kpi USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: kpi_dbname_time_idx; Type: INDEX; Schema: public; Owner: pgwatch2
--

CREATE INDEX kpi_dbname_time_idx ON ONLY public.kpi USING btree (dbname, "time");

