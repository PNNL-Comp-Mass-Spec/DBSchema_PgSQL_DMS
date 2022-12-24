--
-- Name: VW_PUB_SMS_NETWORK_IP_ADDR; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_SMS_NETWORK_IP_ADDR" (
    "SMS_DEVICE_ID" integer NOT NULL,
    "IP_ADDRESS" character varying(255),
    "PHYSICAL_ADDRESS" character varying(32),
    "LAST_SEEN_DTM" timestamp(3) without time zone,
    "DW_ACQ_DATETIME" timestamp(3) without time zone
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_SMS_NETWORK_IP_ADDR'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SMS_NETWORK_IP_ADDR" ALTER COLUMN "SMS_DEVICE_ID" OPTIONS (
    column_name 'SMS_DEVICE_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SMS_NETWORK_IP_ADDR" ALTER COLUMN "IP_ADDRESS" OPTIONS (
    column_name 'IP_ADDRESS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SMS_NETWORK_IP_ADDR" ALTER COLUMN "PHYSICAL_ADDRESS" OPTIONS (
    column_name 'PHYSICAL_ADDRESS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SMS_NETWORK_IP_ADDR" ALTER COLUMN "LAST_SEEN_DTM" OPTIONS (
    column_name 'LAST_SEEN_DTM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SMS_NETWORK_IP_ADDR" ALTER COLUMN "DW_ACQ_DATETIME" OPTIONS (
    column_name 'DW_ACQ_DATETIME'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_SMS_NETWORK_IP_ADDR" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_SMS_NETWORK_IP_ADDR"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_SMS_NETWORK_IP_ADDR" TO writeaccess;

