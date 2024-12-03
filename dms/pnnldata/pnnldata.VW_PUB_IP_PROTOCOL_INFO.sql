--
-- Name: VW_PUB_IP_PROTOCOL_INFO; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_IP_PROTOCOL_INFO" (
    "IP_ADDRESS" character varying(15) NOT NULL,
    "DNS_NAME" character varying(32) NOT NULL,
    "DNS_DOMAIN" character varying(32) NOT NULL,
    "CPU_PROPERTY" character varying(9) NOT NULL,
    "INTERFACE_NAME" character varying(64) NOT NULL,
    "PORT_IDENTIFIER" character varying(10),
    "IP_NETWORK" character varying(15) NOT NULL,
    "GENERATE" character varying(1) NOT NULL,
    "IDX" integer,
    "ALLOCATION_GROUP" character varying(20)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_IP_PROTOCOL_INFO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_PROTOCOL_INFO" ALTER COLUMN "IP_ADDRESS" OPTIONS (
    column_name 'IP_ADDRESS'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_PROTOCOL_INFO" ALTER COLUMN "DNS_NAME" OPTIONS (
    column_name 'DNS_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_PROTOCOL_INFO" ALTER COLUMN "DNS_DOMAIN" OPTIONS (
    column_name 'DNS_DOMAIN'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_PROTOCOL_INFO" ALTER COLUMN "CPU_PROPERTY" OPTIONS (
    column_name 'CPU_PROPERTY'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_PROTOCOL_INFO" ALTER COLUMN "INTERFACE_NAME" OPTIONS (
    column_name 'INTERFACE_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_PROTOCOL_INFO" ALTER COLUMN "PORT_IDENTIFIER" OPTIONS (
    column_name 'PORT_IDENTIFIER'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_PROTOCOL_INFO" ALTER COLUMN "IP_NETWORK" OPTIONS (
    column_name 'IP_NETWORK'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_PROTOCOL_INFO" ALTER COLUMN "GENERATE" OPTIONS (
    column_name 'GENERATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_PROTOCOL_INFO" ALTER COLUMN "IDX" OPTIONS (
    column_name 'IDX'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_IP_PROTOCOL_INFO" ALTER COLUMN "ALLOCATION_GROUP" OPTIONS (
    column_name 'ALLOCATION_GROUP'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_IP_PROTOCOL_INFO" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_IP_PROTOCOL_INFO"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_IP_PROTOCOL_INFO" TO writeaccess;

