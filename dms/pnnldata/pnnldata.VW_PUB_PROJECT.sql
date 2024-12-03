--
-- Name: VW_PUB_PROJECT; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_PROJECT" (
    "PROJ_NO" character varying(8) NOT NULL,
    "SETUP_DATE" timestamp(3) without time zone,
    "ACCT" character varying(6) NOT NULL,
    "RESP_EMPLID" character varying(11) NOT NULL,
    "RESP_PAY_NO" character varying(5),
    "RESP_COST_CD" character varying(6) NOT NULL,
    "PROJ_TITLE" character varying(60) NOT NULL,
    "RPT_CONT_NO" character varying(8) NOT NULL,
    "RPT_PERIOD" character varying(2) NOT NULL,
    "EFF_DATE" timestamp(3) without time zone NOT NULL,
    "INACT_DATE" timestamp(3) without time zone,
    "TBA_CD" character varying(4),
    "BO_TAX_CR_CD" character varying(2),
    "SNM_SW" character varying(1),
    "CTRY_CD" character varying(3),
    "ADMIN_PROJ_SW" character varying(1),
    "LAST_PROP_AMND_NO" character varying(4) NOT NULL,
    "RPT_CLASS" character varying(3),
    "DEACT_SW" character varying(1),
    "DEACT_SW_DATE" timestamp(3) without time zone,
    "LAST_COST_DATE" timestamp(3) without time zone,
    "INVALID_FLG" character varying(1),
    "LAST_CHANGE_DATE" timestamp(3) without time zone NOT NULL,
    "LAST_CHANGE_ID" character varying(30) NOT NULL,
    "PROP_NO" character varying(8),
    "IMPACT_QUAL_LVL" character varying(1),
    "IP_SW" character varying(1),
    "DEL_IND" character varying(1),
    "MISC_FLG" character varying(1),
    "RESP_HID" character varying(7),
    "RECORD_SRC" character varying(20),
    "ME_FY_AMT" integer,
    "ARRA_FUNDS_SW" character varying(1)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_PROJECT'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "PROJ_NO" OPTIONS (
    column_name 'PROJ_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "SETUP_DATE" OPTIONS (
    column_name 'SETUP_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "ACCT" OPTIONS (
    column_name 'ACCT'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "RESP_EMPLID" OPTIONS (
    column_name 'RESP_EMPLID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "RESP_PAY_NO" OPTIONS (
    column_name 'RESP_PAY_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "RESP_COST_CD" OPTIONS (
    column_name 'RESP_COST_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "PROJ_TITLE" OPTIONS (
    column_name 'PROJ_TITLE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "RPT_CONT_NO" OPTIONS (
    column_name 'RPT_CONT_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "RPT_PERIOD" OPTIONS (
    column_name 'RPT_PERIOD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "EFF_DATE" OPTIONS (
    column_name 'EFF_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "INACT_DATE" OPTIONS (
    column_name 'INACT_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "TBA_CD" OPTIONS (
    column_name 'TBA_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "BO_TAX_CR_CD" OPTIONS (
    column_name 'BO_TAX_CR_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "SNM_SW" OPTIONS (
    column_name 'SNM_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "CTRY_CD" OPTIONS (
    column_name 'CTRY_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "ADMIN_PROJ_SW" OPTIONS (
    column_name 'ADMIN_PROJ_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "LAST_PROP_AMND_NO" OPTIONS (
    column_name 'LAST_PROP_AMND_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "RPT_CLASS" OPTIONS (
    column_name 'RPT_CLASS'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "DEACT_SW" OPTIONS (
    column_name 'DEACT_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "DEACT_SW_DATE" OPTIONS (
    column_name 'DEACT_SW_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "LAST_COST_DATE" OPTIONS (
    column_name 'LAST_COST_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "INVALID_FLG" OPTIONS (
    column_name 'INVALID_FLG'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "LAST_CHANGE_DATE" OPTIONS (
    column_name 'LAST_CHANGE_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "LAST_CHANGE_ID" OPTIONS (
    column_name 'LAST_CHANGE_ID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "PROP_NO" OPTIONS (
    column_name 'PROP_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "IMPACT_QUAL_LVL" OPTIONS (
    column_name 'IMPACT_QUAL_LVL'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "IP_SW" OPTIONS (
    column_name 'IP_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "DEL_IND" OPTIONS (
    column_name 'DEL_IND'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "MISC_FLG" OPTIONS (
    column_name 'MISC_FLG'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "RESP_HID" OPTIONS (
    column_name 'RESP_HID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "RECORD_SRC" OPTIONS (
    column_name 'RECORD_SRC'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "ME_FY_AMT" OPTIONS (
    column_name 'ME_FY_AMT'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_PROJECT" ALTER COLUMN "ARRA_FUNDS_SW" OPTIONS (
    column_name 'ARRA_FUNDS_SW'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_PROJECT" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_PROJECT"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_PROJECT" TO writeaccess;

