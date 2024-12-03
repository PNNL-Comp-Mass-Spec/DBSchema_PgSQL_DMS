--
-- Name: VW_PUB_SMS_DEVICE; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_SMS_DEVICE" (
    "SMS_DEVICE_ID" integer,
    "CPU_TYPE" character varying(64),
    "CPU_QTY" integer,
    "DEVICE_NAME" character varying(64),
    "PHYSICAL_MEMORY_BYTES" integer,
    "OS_NAME" character varying(128),
    "OS_VERSION" character varying(16),
    "SMS_DEVICE_TYPE" character varying(50),
    "DEVICE_DOMAIN_NAME" character varying(24),
    "LAST_SEEN_ID" character varying(64),
    "LAST_SEEN_DTM" timestamp(3) without time zone,
    "DW_ACQ_DATETIME" timestamp(3) without time zone
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_SMS_DEVICE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "SMS_DEVICE_ID" OPTIONS (
    column_name 'SMS_DEVICE_ID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "CPU_TYPE" OPTIONS (
    column_name 'CPU_TYPE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "CPU_QTY" OPTIONS (
    column_name 'CPU_QTY'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "DEVICE_NAME" OPTIONS (
    column_name 'DEVICE_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "PHYSICAL_MEMORY_BYTES" OPTIONS (
    column_name 'PHYSICAL_MEMORY_BYTES'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "OS_NAME" OPTIONS (
    column_name 'OS_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "OS_VERSION" OPTIONS (
    column_name 'OS_VERSION'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "SMS_DEVICE_TYPE" OPTIONS (
    column_name 'SMS_DEVICE_TYPE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "DEVICE_DOMAIN_NAME" OPTIONS (
    column_name 'DEVICE_DOMAIN_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "LAST_SEEN_ID" OPTIONS (
    column_name 'LAST_SEEN_ID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "LAST_SEEN_DTM" OPTIONS (
    column_name 'LAST_SEEN_DTM'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SMS_DEVICE" ALTER COLUMN "DW_ACQ_DATETIME" OPTIONS (
    column_name 'DW_ACQ_DATETIME'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_SMS_DEVICE" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_SMS_DEVICE"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_SMS_DEVICE" TO writeaccess;

