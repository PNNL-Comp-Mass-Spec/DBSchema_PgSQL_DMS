--
-- Name: gigasax_fdw; Type: SERVER; Schema: -; Owner: d3l243
--

CREATE SERVER gigasax_fdw FOREIGN DATA WRAPPER tds_fdw OPTIONS (
    database 'DMS5',
    port '1433',
    servername 'gigasax.pnl.gov'
);


ALTER SERVER gigasax_fdw OWNER TO d3l243;

