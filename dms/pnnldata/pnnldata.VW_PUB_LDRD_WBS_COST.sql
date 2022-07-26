--
-- Name: VW_PUB_LDRD_WBS_COST; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_COST" (
    "SUBACCT" character varying(8) NOT NULL,
    "WBS" character varying(13) NOT NULL,
    "FY_BRDN_AMT" numeric(14,2),
    "DW_ACQ_DATETIME" timestamp(3) without time zone NOT NULL
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_LDRD_WBS_COST'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_COST" ALTER COLUMN "SUBACCT" OPTIONS (
    column_name 'SUBACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_COST" ALTER COLUMN "WBS" OPTIONS (
    column_name 'WBS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_COST" ALTER COLUMN "FY_BRDN_AMT" OPTIONS (
    column_name 'FY_BRDN_AMT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_COST" ALTER COLUMN "DW_ACQ_DATETIME" OPTIONS (
    column_name 'DW_ACQ_DATETIME'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_COST" OWNER TO d3l243;

