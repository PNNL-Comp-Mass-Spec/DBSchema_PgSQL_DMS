--
-- Name: VW_PUB_CHARGE_CODE_TRAIL; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" (
    "CHARGE_CD" character varying(6) NOT NULL,
    "ACCT" character varying(6) NOT NULL,
    "SUBACCT" character varying(8),
    "WBS" character varying(13),
    "CA_NO" character varying(4),
    "ACCT_EFF_DATE" timestamp(3) without time zone,
    "ACCT_INACT_DATE" timestamp(3) without time zone,
    "ACCT_SPONSOR_CD" character varying(1),
    "ACCT_ENT" character varying(1),
    "COST_OBJ" character varying(1),
    "ACCT_TYPE" character varying(1),
    "SA_TITLE" character varying(60),
    "SA_RESP_COST_CD" character varying(6),
    "RPT_CLASS" character varying(3),
    "SA_DEACT_SW" character varying(1),
    "SA_EFF_DATE" timestamp(3) without time zone,
    "SA_INACT_DATE" timestamp(3) without time zone,
    "SA_TYPE" character varying(4),
    "SA_AUTH_AMT" numeric(14,2),
    "WBS_TITLE" character varying(60),
    "WBS_RESP_COST_CD" character varying(6),
    "CA_RESP_COST_CD" character varying(6),
    "CC_TITLE" character varying(60) NOT NULL,
    "CC_RESP_COST_CD" character varying(6),
    "CC_RESP_EMPLID" character varying(11),
    "CC_RESP_HID" character varying(7),
    "CC_DEACT_SW" character varying(1) NOT NULL,
    "CC_EFF_DATE" timestamp(3) without time zone NOT NULL,
    "CC_INACT_DATE" timestamp(3) without time zone,
    "CC_AUTH_AMT" numeric(14,2),
    "INVALID_SW" character varying(1) NOT NULL,
    "PER_DIEM_SW" character varying(1),
    "UNALLOW_SW" character varying(1) NOT NULL,
    "CC_UNALLOW_IND" character varying(1)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_CHARGE_CODE_TRAIL'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CHARGE_CD" OPTIONS (
    column_name 'CHARGE_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "ACCT" OPTIONS (
    column_name 'ACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "SUBACCT" OPTIONS (
    column_name 'SUBACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "WBS" OPTIONS (
    column_name 'WBS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CA_NO" OPTIONS (
    column_name 'CA_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "ACCT_EFF_DATE" OPTIONS (
    column_name 'ACCT_EFF_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "ACCT_INACT_DATE" OPTIONS (
    column_name 'ACCT_INACT_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "ACCT_SPONSOR_CD" OPTIONS (
    column_name 'ACCT_SPONSOR_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "ACCT_ENT" OPTIONS (
    column_name 'ACCT_ENT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "COST_OBJ" OPTIONS (
    column_name 'COST_OBJ'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "ACCT_TYPE" OPTIONS (
    column_name 'ACCT_TYPE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "SA_TITLE" OPTIONS (
    column_name 'SA_TITLE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "SA_RESP_COST_CD" OPTIONS (
    column_name 'SA_RESP_COST_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "RPT_CLASS" OPTIONS (
    column_name 'RPT_CLASS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "SA_DEACT_SW" OPTIONS (
    column_name 'SA_DEACT_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "SA_EFF_DATE" OPTIONS (
    column_name 'SA_EFF_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "SA_INACT_DATE" OPTIONS (
    column_name 'SA_INACT_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "SA_TYPE" OPTIONS (
    column_name 'SA_TYPE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "SA_AUTH_AMT" OPTIONS (
    column_name 'SA_AUTH_AMT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "WBS_TITLE" OPTIONS (
    column_name 'WBS_TITLE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "WBS_RESP_COST_CD" OPTIONS (
    column_name 'WBS_RESP_COST_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CA_RESP_COST_CD" OPTIONS (
    column_name 'CA_RESP_COST_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CC_TITLE" OPTIONS (
    column_name 'CC_TITLE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CC_RESP_COST_CD" OPTIONS (
    column_name 'CC_RESP_COST_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CC_RESP_EMPLID" OPTIONS (
    column_name 'CC_RESP_EMPLID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CC_RESP_HID" OPTIONS (
    column_name 'CC_RESP_HID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CC_DEACT_SW" OPTIONS (
    column_name 'CC_DEACT_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CC_EFF_DATE" OPTIONS (
    column_name 'CC_EFF_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CC_INACT_DATE" OPTIONS (
    column_name 'CC_INACT_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CC_AUTH_AMT" OPTIONS (
    column_name 'CC_AUTH_AMT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "INVALID_SW" OPTIONS (
    column_name 'INVALID_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "PER_DIEM_SW" OPTIONS (
    column_name 'PER_DIEM_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "UNALLOW_SW" OPTIONS (
    column_name 'UNALLOW_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" ALTER COLUMN "CC_UNALLOW_IND" OPTIONS (
    column_name 'CC_UNALLOW_IND'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE_TRAIL" OWNER TO d3l243;

