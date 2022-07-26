--
-- Name: VW_PUB_FACILITY; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_FACILITY" (
    "FACILITY_ID" character varying(11) NOT NULL,
    "ACTIVE_SW" character varying(1) NOT NULL,
    "AREA" character varying(6),
    "BENEFICIAL_USE_DATE" timestamp(3) without time zone,
    "BLD_CD" character varying(1),
    "BRS_RPT_MAIL_STOP" character varying(7),
    "CITY" character varying(50),
    "COUNTY" character varying(25),
    "CTRY_CD" character varying(3),
    "DOE_FACILITY_ID" character varying(12),
    "FACILITY_MGR_HID" character varying(7),
    "FACILITY_NAME" character varying(35),
    "FACILITY_OWNER_CD" character varying(1),
    "FACILITY_SHORT_NAME" character varying(16) NOT NULL,
    "FACILITY_TYPE_CD" character varying(3),
    "IOPS_FACILITY_SW" character varying(1),
    "STATE_CD" character varying(2),
    "STREET_ADDRESS" character varying(55),
    "YEAR_ACQUIRED" character varying(4),
    "YEAR_CONST_COMPLETED" character varying(4),
    "ZIP_CD" character varying(10),
    "CONSOLIDATED_LAB_SW" character(1),
    "PNNL_FIN_RESP_CD" character varying(1),
    "OWNER_CD" character varying(8),
    "STATUS_CD" character varying(16),
    "FACILITY_CAT_CD" character varying(8),
    "FACILITY_SUB_CAT_CD" character varying(8),
    "LOCATION" character varying(10),
    "LIFECYCLE_STATUS" character varying(15)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_FACILITY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "FACILITY_ID" OPTIONS (
    column_name 'FACILITY_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "ACTIVE_SW" OPTIONS (
    column_name 'ACTIVE_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "AREA" OPTIONS (
    column_name 'AREA'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "BENEFICIAL_USE_DATE" OPTIONS (
    column_name 'BENEFICIAL_USE_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "BLD_CD" OPTIONS (
    column_name 'BLD_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "BRS_RPT_MAIL_STOP" OPTIONS (
    column_name 'BRS_RPT_MAIL_STOP'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "CITY" OPTIONS (
    column_name 'CITY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "COUNTY" OPTIONS (
    column_name 'COUNTY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "CTRY_CD" OPTIONS (
    column_name 'CTRY_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "DOE_FACILITY_ID" OPTIONS (
    column_name 'DOE_FACILITY_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "FACILITY_MGR_HID" OPTIONS (
    column_name 'FACILITY_MGR_HID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "FACILITY_NAME" OPTIONS (
    column_name 'FACILITY_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "FACILITY_OWNER_CD" OPTIONS (
    column_name 'FACILITY_OWNER_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "FACILITY_SHORT_NAME" OPTIONS (
    column_name 'FACILITY_SHORT_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "FACILITY_TYPE_CD" OPTIONS (
    column_name 'FACILITY_TYPE_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "IOPS_FACILITY_SW" OPTIONS (
    column_name 'IOPS_FACILITY_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "STATE_CD" OPTIONS (
    column_name 'STATE_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "STREET_ADDRESS" OPTIONS (
    column_name 'STREET_ADDRESS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "YEAR_ACQUIRED" OPTIONS (
    column_name 'YEAR_ACQUIRED'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "YEAR_CONST_COMPLETED" OPTIONS (
    column_name 'YEAR_CONST_COMPLETED'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "ZIP_CD" OPTIONS (
    column_name 'ZIP_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "CONSOLIDATED_LAB_SW" OPTIONS (
    column_name 'CONSOLIDATED_LAB_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "PNNL_FIN_RESP_CD" OPTIONS (
    column_name 'PNNL_FIN_RESP_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "OWNER_CD" OPTIONS (
    column_name 'OWNER_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "STATUS_CD" OPTIONS (
    column_name 'STATUS_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "FACILITY_CAT_CD" OPTIONS (
    column_name 'FACILITY_CAT_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "FACILITY_SUB_CAT_CD" OPTIONS (
    column_name 'FACILITY_SUB_CAT_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "LOCATION" OPTIONS (
    column_name 'LOCATION'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" ALTER COLUMN "LIFECYCLE_STATUS" OPTIONS (
    column_name 'LIFECYCLE_STATUS'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY" OWNER TO d3l243;

