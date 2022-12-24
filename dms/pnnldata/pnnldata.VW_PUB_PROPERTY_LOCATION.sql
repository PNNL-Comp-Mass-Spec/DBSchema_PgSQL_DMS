--
-- Name: VW_PUB_PROPERTY_LOCATION; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" (
    "PROPTY_NO" character varying(9) NOT NULL,
    "AREA" character varying(5),
    "BLD_NO" character varying(11),
    "CUSTD_CD" character varying(6),
    "EQPT_AVAIL_CD" character varying(1),
    "EQPT_COND_CD" character varying(1),
    "HOME_BASE_SW" character varying(1),
    "INVNT_DATE" timestamp(3) without time zone,
    "INVNT_TYPE" character varying(60),
    "INVNT_RSLT_CD" character varying(1),
    "INVNT_SEL_CD" character varying(1),
    "LANDLORD_PROPTY_SW" character varying(1),
    "ON_OFF_PLANT_SW" character varying(1),
    "PROPTY_TAX_DISTRC" character varying(15),
    "PROPTY_TAX_STATE" character varying(2),
    "ROOM" character varying(20),
    "SUB_CUSTD_CD" character varying(6),
    "USER_NAME" character varying(20),
    "USER_HID" character varying(7),
    "USER_PAY_NO" character varying(5),
    "USER_EMPLID" character varying(11),
    "DEL_IND" character varying(1),
    "PROPERTY_REP" character varying(40),
    "MISC_FLG" character varying(1),
    "RECORD_SRC" character varying(20),
    "LAST_CHANGE_ID" character varying(6),
    "LAST_CHANGE_DATE" timestamp(3) without time zone,
    "PROPERTY_REP_EMPLID" character varying(11),
    "LOCATION_COMMENT" character varying(60)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_PROPERTY_LOCATION'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "PROPTY_NO" OPTIONS (
    column_name 'PROPTY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "AREA" OPTIONS (
    column_name 'AREA'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "BLD_NO" OPTIONS (
    column_name 'BLD_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "CUSTD_CD" OPTIONS (
    column_name 'CUSTD_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "EQPT_AVAIL_CD" OPTIONS (
    column_name 'EQPT_AVAIL_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "EQPT_COND_CD" OPTIONS (
    column_name 'EQPT_COND_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "HOME_BASE_SW" OPTIONS (
    column_name 'HOME_BASE_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "INVNT_DATE" OPTIONS (
    column_name 'INVNT_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "INVNT_TYPE" OPTIONS (
    column_name 'INVNT_TYPE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "INVNT_RSLT_CD" OPTIONS (
    column_name 'INVNT_RSLT_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "INVNT_SEL_CD" OPTIONS (
    column_name 'INVNT_SEL_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "LANDLORD_PROPTY_SW" OPTIONS (
    column_name 'LANDLORD_PROPTY_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "ON_OFF_PLANT_SW" OPTIONS (
    column_name 'ON_OFF_PLANT_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "PROPTY_TAX_DISTRC" OPTIONS (
    column_name 'PROPTY_TAX_DISTRC'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "PROPTY_TAX_STATE" OPTIONS (
    column_name 'PROPTY_TAX_STATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "ROOM" OPTIONS (
    column_name 'ROOM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "SUB_CUSTD_CD" OPTIONS (
    column_name 'SUB_CUSTD_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "USER_NAME" OPTIONS (
    column_name 'USER_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "USER_HID" OPTIONS (
    column_name 'USER_HID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "USER_PAY_NO" OPTIONS (
    column_name 'USER_PAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "USER_EMPLID" OPTIONS (
    column_name 'USER_EMPLID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "DEL_IND" OPTIONS (
    column_name 'DEL_IND'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "PROPERTY_REP" OPTIONS (
    column_name 'PROPERTY_REP'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "MISC_FLG" OPTIONS (
    column_name 'MISC_FLG'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "RECORD_SRC" OPTIONS (
    column_name 'RECORD_SRC'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "LAST_CHANGE_ID" OPTIONS (
    column_name 'LAST_CHANGE_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "LAST_CHANGE_DATE" OPTIONS (
    column_name 'LAST_CHANGE_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "PROPERTY_REP_EMPLID" OPTIONS (
    column_name 'PROPERTY_REP_EMPLID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" ALTER COLUMN "LOCATION_COMMENT" OPTIONS (
    column_name 'LOCATION_COMMENT'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_PROPERTY_LOCATION"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_PROPERTY_LOCATION" TO writeaccess;

