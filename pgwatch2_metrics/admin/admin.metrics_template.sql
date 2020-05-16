--
-- Name: metrics_template; Type: TABLE; Schema: admin; Owner: pgwatch2
--

CREATE TABLE admin.metrics_template (
    "time" timestamp with time zone DEFAULT now() NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb,
    CONSTRAINT metrics_template_check CHECK (false)
);


ALTER TABLE admin.metrics_template OWNER TO pgwatch2;

--
-- Name: TABLE metrics_template; Type: COMMENT; Schema: admin; Owner: pgwatch2
--

COMMENT ON TABLE admin.metrics_template IS 'used as a template for all new metric definitions';

--
-- Name: metrics_template_dbname_tag_data_time_idx; Type: INDEX; Schema: admin; Owner: pgwatch2
--

CREATE INDEX metrics_template_dbname_tag_data_time_idx ON admin.metrics_template USING gin (dbname, tag_data, "time") WHERE (tag_data IS NOT NULL);

--
-- Name: metrics_template_dbname_time_idx; Type: INDEX; Schema: admin; Owner: pgwatch2
--

CREATE INDEX metrics_template_dbname_time_idx ON admin.metrics_template USING btree (dbname, "time");

