--
-- Name: VW_PUB_CHARGE_CODE; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE" (
    "CHARGE_CD" character varying(6) NOT NULL,
    "AUTH_AMT" numeric(12,0) NOT NULL,
    "AUTH_HID" character varying(7),
    "AUTH_PAY_NO" character varying(5),
    "CA_NO" character varying(4),
    "OVHD_ACTV_CD" character varying(4),
    "RCVR_ENT_ORG" character varying(6),
    "RCVR_ENT_SUBACCT" character varying(8),
    "RESP_HID" character varying(7),
    "RESP_PAY_NO" character varying(5),
    "SETUP_DATE" timestamp(3) without time zone NOT NULL,
    "SUBACCT" character varying(8),
    "TBA_CD" character varying(4),
    "TRI_PARTY_AGREEMENT_SW" character(1),
    "TRI_PARTY_MILESTONE_NO" character varying(7),
    "CHARGE_CD_REPLACE_NO" character varying(6),
    "CHARGE_CD_TITLE" character varying(30),
    "EFF_DATE" timestamp(3) without time zone NOT NULL,
    "INVALID_FLG" character varying(1),
    "INACT_DATE" timestamp(3) without time zone,
    "INACT_REASON" character varying(3),
    "DEACT_SW" character varying(1) NOT NULL,
    "RECORD_SRC" character varying(20),
    "SUBACCT_EFF_DATE" timestamp(3) without time zone,
    "SUBACCT_INACT_DATE" timestamp(3) without time zone,
    "SUBACCT_DEACT_SW" character varying(1),
    "DEL_IND" integer,
    "MISC_FLG" integer
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_CHARGE_CODE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "CHARGE_CD" OPTIONS (
    column_name 'CHARGE_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "AUTH_AMT" OPTIONS (
    column_name 'AUTH_AMT'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "AUTH_HID" OPTIONS (
    column_name 'AUTH_HID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "AUTH_PAY_NO" OPTIONS (
    column_name 'AUTH_PAY_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "CA_NO" OPTIONS (
    column_name 'CA_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "OVHD_ACTV_CD" OPTIONS (
    column_name 'OVHD_ACTV_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "RCVR_ENT_ORG" OPTIONS (
    column_name 'RCVR_ENT_ORG'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "RCVR_ENT_SUBACCT" OPTIONS (
    column_name 'RCVR_ENT_SUBACCT'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "RESP_HID" OPTIONS (
    column_name 'RESP_HID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "RESP_PAY_NO" OPTIONS (
    column_name 'RESP_PAY_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "SETUP_DATE" OPTIONS (
    column_name 'SETUP_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "SUBACCT" OPTIONS (
    column_name 'SUBACCT'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "TBA_CD" OPTIONS (
    column_name 'TBA_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "TRI_PARTY_AGREEMENT_SW" OPTIONS (
    column_name 'TRI_PARTY_AGREEMENT_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "TRI_PARTY_MILESTONE_NO" OPTIONS (
    column_name 'TRI_PARTY_MILESTONE_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "CHARGE_CD_REPLACE_NO" OPTIONS (
    column_name 'CHARGE_CD_REPLACE_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "CHARGE_CD_TITLE" OPTIONS (
    column_name 'CHARGE_CD_TITLE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "EFF_DATE" OPTIONS (
    column_name 'EFF_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "INVALID_FLG" OPTIONS (
    column_name 'INVALID_FLG'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "INACT_DATE" OPTIONS (
    column_name 'INACT_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "INACT_REASON" OPTIONS (
    column_name 'INACT_REASON'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "DEACT_SW" OPTIONS (
    column_name 'DEACT_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "RECORD_SRC" OPTIONS (
    column_name 'RECORD_SRC'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "SUBACCT_EFF_DATE" OPTIONS (
    column_name 'SUBACCT_EFF_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "SUBACCT_INACT_DATE" OPTIONS (
    column_name 'SUBACCT_INACT_DATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "SUBACCT_DEACT_SW" OPTIONS (
    column_name 'SUBACCT_DEACT_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "DEL_IND" OPTIONS (
    column_name 'DEL_IND'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_CHARGE_CODE" ALTER COLUMN "MISC_FLG" OPTIONS (
    column_name 'MISC_FLG'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_CHARGE_CODE" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_CHARGE_CODE"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_CHARGE_CODE" TO writeaccess;

