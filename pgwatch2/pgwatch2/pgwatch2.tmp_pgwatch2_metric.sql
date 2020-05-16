--
-- Name: tmp_pgwatch2_metric; Type: TABLE; Schema: pgwatch2; Owner: postgres
--

CREATE UNLOGGED TABLE pgwatch2.tmp_pgwatch2_metric (
    m_id integer,
    m_name text,
    m_pg_version_from numeric,
    m_sql text,
    m_comment text,
    m_is_active boolean,
    m_is_helper boolean,
    m_last_modified_on timestamp with time zone,
    m_master_only boolean,
    m_standby_only boolean,
    m_column_attrs jsonb,
    m_sql_su text
);


ALTER TABLE pgwatch2.tmp_pgwatch2_metric OWNER TO postgres;

