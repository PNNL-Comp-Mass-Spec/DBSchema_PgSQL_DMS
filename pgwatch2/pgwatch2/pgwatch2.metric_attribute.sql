--
-- Name: metric_attribute; Type: TABLE; Schema: pgwatch2; Owner: pgwatch2
--

CREATE TABLE pgwatch2.metric_attribute (
    ma_metric_name text NOT NULL,
    ma_last_modified_on timestamp with time zone DEFAULT now() NOT NULL,
    ma_metric_attrs jsonb NOT NULL,
    CONSTRAINT metric_attribute_ma_metric_name_check CHECK ((ma_metric_name ~ '^[a-z0-9_]+$'::text))
);


ALTER TABLE pgwatch2.metric_attribute OWNER TO pgwatch2;

--
-- Name: metric_m_id_seq; Type: SEQUENCE; Schema: pgwatch2; Owner: pgwatch2
--

CREATE SEQUENCE pgwatch2.metric_m_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pgwatch2.metric_m_id_seq OWNER TO pgwatch2;

--
-- Name: metric_m_id_seq; Type: SEQUENCE OWNED BY; Schema: pgwatch2; Owner: pgwatch2
--

ALTER SEQUENCE pgwatch2.metric_m_id_seq OWNED BY pgwatch2.metric.m_id;

--
-- Name: metric_attribute metric_attribute_pkey; Type: CONSTRAINT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.metric_attribute
    ADD CONSTRAINT metric_attribute_pkey PRIMARY KEY (ma_metric_name);

