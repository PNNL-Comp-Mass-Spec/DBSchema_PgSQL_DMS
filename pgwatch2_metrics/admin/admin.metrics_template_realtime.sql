--
-- Name: metrics_template_realtime; Type: TABLE; Schema: admin; Owner: pgwatch2
--

CREATE UNLOGGED TABLE admin.metrics_template_realtime (
    "time" timestamp with time zone DEFAULT now() NOT NULL,
    dbname text NOT NULL,
    data jsonb NOT NULL,
    tag_data jsonb,
    CONSTRAINT metrics_template_realtime_check CHECK (false)
);


ALTER TABLE admin.metrics_template_realtime OWNER TO pgwatch2;

--
-- Name: TABLE metrics_template_realtime; Type: COMMENT; Schema: admin; Owner: pgwatch2
--

COMMENT ON TABLE admin.metrics_template_realtime IS 'used as a template for all new realtime metric definitions';

--
-- Name: metrics_template_realtime_dbname_time_idx; Type: INDEX; Schema: admin; Owner: pgwatch2
--

CREATE INDEX metrics_template_realtime_dbname_time_idx ON admin.metrics_template_realtime USING btree (dbname, "time");

