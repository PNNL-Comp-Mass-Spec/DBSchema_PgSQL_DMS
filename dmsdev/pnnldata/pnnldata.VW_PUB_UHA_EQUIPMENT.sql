--
-- Name: VW_PUB_UHA_EQUIPMENT; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" (
    "PROPERTY_TAG" character varying(9) NOT NULL,
    "NODE_NAME" character varying(32),
    "ACCT_UPLOAD_DATE" timestamp(3) without time zone,
    "SYSINFO_UPLOAD_DATE" timestamp(3) without time zone,
    "RASD_DATE" timestamp(3) without time zone NOT NULL,
    "SYS_STATUS" character varying(11),
    "OWNER_ID" character varying(8),
    "PRIMARY_USER_ID" character varying(8),
    "USING_ORG_CD" character varying(6),
    "OWNING_ORG_CD" character varying(6),
    "SYS_MODEL" character varying(40),
    "SENSITIVITY" character varying(2),
    "SYS_CLASS" character varying(18),
    "SITE_ADDR" character varying(10),
    "SYS_TYPE" character varying(9),
    "SYS_BUILDING_ADDR" character varying(11),
    "SYS_ROOM_ADDR" character varying(25),
    "SYS_SERIAL_NO" character varying(24),
    "PROCESSOR" character varying(40),
    "MEMORY_CAPACITY" integer,
    "OS_NAME" character varying(16),
    "OS_VERSION" character varying(8),
    "SYS_MANUFACTURER" character varying(80),
    "ARCHITECTURE" character varying(10),
    "NO_PROCESSORS" smallint,
    "HOST_ID" character varying(50),
    "KERNEL_VERSION" character varying(80),
    "AT_SYS_EXPAN" character varying(50),
    "MAIL_CONFIG" character varying(16),
    "AHMS_CLIENT" character varying(2),
    "LAST_SEEN_DATE" timestamp(3) without time zone,
    "LAST_REBOOT_DATE" timestamp(3) without time zone,
    "DESCR" character varying(80),
    "ACCT_REQUESTABILITY" character varying(16),
    "DELEGATE_ID" character varying(8)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_UHA_EQUIPMENT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "PROPERTY_TAG" OPTIONS (
    column_name 'PROPERTY_TAG'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "NODE_NAME" OPTIONS (
    column_name 'NODE_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "ACCT_UPLOAD_DATE" OPTIONS (
    column_name 'ACCT_UPLOAD_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SYSINFO_UPLOAD_DATE" OPTIONS (
    column_name 'SYSINFO_UPLOAD_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "RASD_DATE" OPTIONS (
    column_name 'RASD_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SYS_STATUS" OPTIONS (
    column_name 'SYS_STATUS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "OWNER_ID" OPTIONS (
    column_name 'OWNER_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "PRIMARY_USER_ID" OPTIONS (
    column_name 'PRIMARY_USER_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "USING_ORG_CD" OPTIONS (
    column_name 'USING_ORG_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "OWNING_ORG_CD" OPTIONS (
    column_name 'OWNING_ORG_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SYS_MODEL" OPTIONS (
    column_name 'SYS_MODEL'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SENSITIVITY" OPTIONS (
    column_name 'SENSITIVITY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SYS_CLASS" OPTIONS (
    column_name 'SYS_CLASS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SITE_ADDR" OPTIONS (
    column_name 'SITE_ADDR'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SYS_TYPE" OPTIONS (
    column_name 'SYS_TYPE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SYS_BUILDING_ADDR" OPTIONS (
    column_name 'SYS_BUILDING_ADDR'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SYS_ROOM_ADDR" OPTIONS (
    column_name 'SYS_ROOM_ADDR'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SYS_SERIAL_NO" OPTIONS (
    column_name 'SYS_SERIAL_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "PROCESSOR" OPTIONS (
    column_name 'PROCESSOR'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "MEMORY_CAPACITY" OPTIONS (
    column_name 'MEMORY_CAPACITY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "OS_NAME" OPTIONS (
    column_name 'OS_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "OS_VERSION" OPTIONS (
    column_name 'OS_VERSION'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "SYS_MANUFACTURER" OPTIONS (
    column_name 'SYS_MANUFACTURER'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "ARCHITECTURE" OPTIONS (
    column_name 'ARCHITECTURE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "NO_PROCESSORS" OPTIONS (
    column_name 'NO_PROCESSORS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "HOST_ID" OPTIONS (
    column_name 'HOST_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "KERNEL_VERSION" OPTIONS (
    column_name 'KERNEL_VERSION'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "AT_SYS_EXPAN" OPTIONS (
    column_name 'AT_SYS_EXPAN'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "MAIL_CONFIG" OPTIONS (
    column_name 'MAIL_CONFIG'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "AHMS_CLIENT" OPTIONS (
    column_name 'AHMS_CLIENT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "LAST_SEEN_DATE" OPTIONS (
    column_name 'LAST_SEEN_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "LAST_REBOOT_DATE" OPTIONS (
    column_name 'LAST_REBOOT_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "DESCR" OPTIONS (
    column_name 'DESCR'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "ACCT_REQUESTABILITY" OPTIONS (
    column_name 'ACCT_REQUESTABILITY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" ALTER COLUMN "DELEGATE_ID" OPTIONS (
    column_name 'DELEGATE_ID'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_UHA_EQUIPMENT"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_UHA_EQUIPMENT" TO writeaccess;

