--
-- Name: op_warehouse_fdw; Type: SERVER; Schema: -; Owner: d3l243
--

CREATE SERVER op_warehouse_fdw FOREIGN DATA WRAPPER tds_fdw OPTIONS (
    database 'OPWHSE',
    port '915',
    servername 'SQLSrvProd02.pnl.gov'
);


ALTER SERVER op_warehouse_fdw OWNER TO d3l243;

