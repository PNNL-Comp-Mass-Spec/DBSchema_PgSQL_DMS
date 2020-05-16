--
-- Name: all_distinct_dbname_metrics; Type: TABLE; Schema: admin; Owner: pgwatch2
--

CREATE TABLE admin.all_distinct_dbname_metrics (
    dbname text NOT NULL,
    metric text NOT NULL,
    created_on timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE admin.all_distinct_dbname_metrics OWNER TO pgwatch2;

--
-- Name: all_distinct_dbname_metrics all_distinct_dbname_metrics_pkey; Type: CONSTRAINT; Schema: admin; Owner: pgwatch2
--

ALTER TABLE ONLY admin.all_distinct_dbname_metrics
    ADD CONSTRAINT all_distinct_dbname_metrics_pkey PRIMARY KEY (dbname, metric);

