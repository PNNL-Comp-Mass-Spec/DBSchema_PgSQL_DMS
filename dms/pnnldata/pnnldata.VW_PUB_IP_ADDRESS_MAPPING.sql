--
-- Name: VW_PUB_IP_ADDRESS_MAPPING; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_IP_ADDRESS_MAPPING" (
    "IP_ADDRESS" character varying(15) NOT NULL,
    "COMPUTER_NAME" character varying(32) NOT NULL,
    "MAC_ADDRESS" character varying(20),
    "PROPTY_NO" character varying(50),
    "ENCLAVE" character varying(20),
    "IP_NETWORK" character varying(15),
    "NETMASK" character varying(15),
    "ENTRY_DATETIME" timestamp(3) without time zone
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_IP_ADDRESS_MAPPING'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_ADDRESS_MAPPING" ALTER COLUMN "IP_ADDRESS" OPTIONS (
    column_name 'IP_ADDRESS'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_ADDRESS_MAPPING" ALTER COLUMN "COMPUTER_NAME" OPTIONS (
    column_name 'COMPUTER_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_ADDRESS_MAPPING" ALTER COLUMN "MAC_ADDRESS" OPTIONS (
    column_name 'MAC_ADDRESS'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_ADDRESS_MAPPING" ALTER COLUMN "PROPTY_NO" OPTIONS (
    column_name 'PROPTY_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_ADDRESS_MAPPING" ALTER COLUMN "ENCLAVE" OPTIONS (
    column_name 'ENCLAVE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_ADDRESS_MAPPING" ALTER COLUMN "IP_NETWORK" OPTIONS (
    column_name 'IP_NETWORK'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_ADDRESS_MAPPING" ALTER COLUMN "NETMASK" OPTIONS (
    column_name 'NETMASK'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_ADDRESS_MAPPING" ALTER COLUMN "ENTRY_DATETIME" OPTIONS (
    column_name 'ENTRY_DATETIME'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_IP_ADDRESS_MAPPING" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_IP_ADDRESS_MAPPING"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_IP_ADDRESS_MAPPING" TO writeaccess;

