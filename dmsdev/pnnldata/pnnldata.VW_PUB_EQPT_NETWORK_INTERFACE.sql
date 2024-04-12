--
-- Name: VW_PUB_EQPT_NETWORK_INTERFACE; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" (
    "EQPT_GUID" character varying(50) NOT NULL,
    "MAC_ADDRESS" character varying(20) NOT NULL,
    "INTERFACE_NAME" character varying(255),
    "DHCP_SERVER_IP_ADDRESS" character varying(15),
    "DEFAULT_GATEWAY_IP_ADDRESS" character varying(15),
    "ACTIVE_SW" character(1) NOT NULL,
    "ENTRY_DATETIME" timestamp(3) without time zone NOT NULL,
    "UPDATE_DATETIME" timestamp(3) without time zone NOT NULL
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_EQPT_NETWORK_INTERFACE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" ALTER COLUMN "EQPT_GUID" OPTIONS (
    column_name 'EQPT_GUID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" ALTER COLUMN "MAC_ADDRESS" OPTIONS (
    column_name 'MAC_ADDRESS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" ALTER COLUMN "INTERFACE_NAME" OPTIONS (
    column_name 'INTERFACE_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" ALTER COLUMN "DHCP_SERVER_IP_ADDRESS" OPTIONS (
    column_name 'DHCP_SERVER_IP_ADDRESS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" ALTER COLUMN "DEFAULT_GATEWAY_IP_ADDRESS" OPTIONS (
    column_name 'DEFAULT_GATEWAY_IP_ADDRESS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" ALTER COLUMN "ACTIVE_SW" OPTIONS (
    column_name 'ACTIVE_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" ALTER COLUMN "ENTRY_DATETIME" OPTIONS (
    column_name 'ENTRY_DATETIME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" ALTER COLUMN "UPDATE_DATETIME" OPTIONS (
    column_name 'UPDATE_DATETIME'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_EQPT_NETWORK_INTERFACE"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_EQPT_NETWORK_INTERFACE" TO writeaccess;

