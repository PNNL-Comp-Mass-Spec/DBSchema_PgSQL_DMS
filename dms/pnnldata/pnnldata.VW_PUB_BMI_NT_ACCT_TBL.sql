--
-- Name: VW_PUB_BMI_NT_ACCT_TBL; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_BMI_NT_ACCT_TBL" (
    "NETWORK_ID" character varying(40),
    "EMPLID" character varying(15),
    "NETWORK_DOMAIN" character varying(256) NOT NULL,
    "HANFORD_ID" character varying(7),
    "TRAINING_ID" character varying(15),
    "DW_ACQ_DATETIME" timestamp(3) without time zone NOT NULL
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_BMI_NT_ACCT_TBL'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_BMI_NT_ACCT_TBL" ALTER COLUMN "NETWORK_ID" OPTIONS (
    column_name 'NETWORK_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_BMI_NT_ACCT_TBL" ALTER COLUMN "EMPLID" OPTIONS (
    column_name 'EMPLID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_BMI_NT_ACCT_TBL" ALTER COLUMN "NETWORK_DOMAIN" OPTIONS (
    column_name 'NETWORK_DOMAIN'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_BMI_NT_ACCT_TBL" ALTER COLUMN "HANFORD_ID" OPTIONS (
    column_name 'HANFORD_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_BMI_NT_ACCT_TBL" ALTER COLUMN "TRAINING_ID" OPTIONS (
    column_name 'TRAINING_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_BMI_NT_ACCT_TBL" ALTER COLUMN "DW_ACQ_DATETIME" OPTIONS (
    column_name 'DW_ACQ_DATETIME'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_BMI_NT_ACCT_TBL" OWNER TO d3l243;

