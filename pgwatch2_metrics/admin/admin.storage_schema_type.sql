--
-- Name: storage_schema_type; Type: TABLE; Schema: admin; Owner: pgwatch2
--

CREATE TABLE admin.storage_schema_type (
    schema_type text NOT NULL,
    initialized_on timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT storage_schema_type_schema_type_check CHECK ((schema_type = ANY (ARRAY['metric'::text, 'metric-time'::text, 'metric-dbname-time'::text, 'custom'::text, 'timescale'::text])))
);


ALTER TABLE admin.storage_schema_type OWNER TO pgwatch2;

--
-- Name: TABLE storage_schema_type; Type: COMMENT; Schema: admin; Owner: pgwatch2
--

COMMENT ON TABLE admin.storage_schema_type IS 'identifies storage schema for other pgwatch2 components';

--
-- Name: max_one_row; Type: INDEX; Schema: admin; Owner: pgwatch2
--

CREATE UNIQUE INDEX max_one_row ON admin.storage_schema_type USING btree ((1));

