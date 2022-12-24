--
-- Name: VW_PUB_ACCT; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_ACCT" (
    "ACCT" character varying(6) NOT NULL,
    "ACCT_TITLE" character varying(30) NOT NULL,
    "ACCT_CATEGORY" character varying(3) NOT NULL,
    "RPT_PERIOD" character varying(2) NOT NULL,
    "SGL_ACCT" character varying(6),
    "ACCT_TYPE" character varying(1),
    "ENT" character varying(1) NOT NULL,
    "COST_OBJ" character varying(1),
    "CLOSE_TOE" character varying(4),
    "CONT_SUSP_SUBACCT" character varying(8),
    "VAR_CHARGE_CD" character varying(6),
    "VAR_SUBACCT" character varying(8),
    "FIN_PLAN" character varying(2),
    "DISCAS_ACCT" character varying(4),
    "DISCAS_BR_SW" character varying(1) NOT NULL,
    "OPI_SW" character varying(1) NOT NULL,
    "INVOICE_RPT_SW" character varying(1) NOT NULL,
    "EFF_DATE" timestamp(3) without time zone NOT NULL,
    "INACT_DATE" timestamp(3) without time zone,
    "DEACT_SW" character varying(1) NOT NULL,
    "RESP_EMPLID" character varying(11),
    "RESP_COST_CD" character varying(6),
    "SPONSOR_CD" character varying(1),
    "LAST_CHANGE_DATE" timestamp(3) without time zone,
    "LAST_CHANGE_ID" character varying(30),
    "RECORD_SRC" character varying(20),
    "RESP_ORG" character varying(6),
    "RESP_PAY_NO" character varying(5),
    "DEL_IND" character varying(1),
    "MISC_FLG" character varying(1),
    "BU_LBR_CAT" character varying(4),
    "RPT_611A_SW" character varying(1),
    "ASSIGNMENT_TYPE" character varying(3)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_ACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "ACCT" OPTIONS (
    column_name 'ACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "ACCT_TITLE" OPTIONS (
    column_name 'ACCT_TITLE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "ACCT_CATEGORY" OPTIONS (
    column_name 'ACCT_CATEGORY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "RPT_PERIOD" OPTIONS (
    column_name 'RPT_PERIOD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "SGL_ACCT" OPTIONS (
    column_name 'SGL_ACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "ACCT_TYPE" OPTIONS (
    column_name 'ACCT_TYPE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "ENT" OPTIONS (
    column_name 'ENT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "COST_OBJ" OPTIONS (
    column_name 'COST_OBJ'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "CLOSE_TOE" OPTIONS (
    column_name 'CLOSE_TOE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "CONT_SUSP_SUBACCT" OPTIONS (
    column_name 'CONT_SUSP_SUBACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "VAR_CHARGE_CD" OPTIONS (
    column_name 'VAR_CHARGE_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "VAR_SUBACCT" OPTIONS (
    column_name 'VAR_SUBACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "FIN_PLAN" OPTIONS (
    column_name 'FIN_PLAN'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "DISCAS_ACCT" OPTIONS (
    column_name 'DISCAS_ACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "DISCAS_BR_SW" OPTIONS (
    column_name 'DISCAS_BR_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "OPI_SW" OPTIONS (
    column_name 'OPI_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "INVOICE_RPT_SW" OPTIONS (
    column_name 'INVOICE_RPT_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "EFF_DATE" OPTIONS (
    column_name 'EFF_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "INACT_DATE" OPTIONS (
    column_name 'INACT_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "DEACT_SW" OPTIONS (
    column_name 'DEACT_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "RESP_EMPLID" OPTIONS (
    column_name 'RESP_EMPLID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "RESP_COST_CD" OPTIONS (
    column_name 'RESP_COST_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "SPONSOR_CD" OPTIONS (
    column_name 'SPONSOR_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "LAST_CHANGE_DATE" OPTIONS (
    column_name 'LAST_CHANGE_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "LAST_CHANGE_ID" OPTIONS (
    column_name 'LAST_CHANGE_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "RECORD_SRC" OPTIONS (
    column_name 'RECORD_SRC'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "RESP_ORG" OPTIONS (
    column_name 'RESP_ORG'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "RESP_PAY_NO" OPTIONS (
    column_name 'RESP_PAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "DEL_IND" OPTIONS (
    column_name 'DEL_IND'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "MISC_FLG" OPTIONS (
    column_name 'MISC_FLG'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "BU_LBR_CAT" OPTIONS (
    column_name 'BU_LBR_CAT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "RPT_611A_SW" OPTIONS (
    column_name 'RPT_611A_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" ALTER COLUMN "ASSIGNMENT_TYPE" OPTIONS (
    column_name 'ASSIGNMENT_TYPE'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_ACCT" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_ACCT"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_ACCT" TO writeaccess;

