--
-- Name: nexus_fdw; Type: SERVER; Schema: -; Owner: d3l243
--

CREATE SERVER nexus_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'nexus_db_production_20210226',
    host 'nexus-prod-db.emsl.pnl.gov',
    port '5432'
);


ALTER SERVER nexus_fdw OWNER TO d3l243;

