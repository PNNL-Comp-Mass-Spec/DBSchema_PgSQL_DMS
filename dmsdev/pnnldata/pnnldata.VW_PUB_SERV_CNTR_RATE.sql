--
-- Name: VW_PUB_SERV_CNTR_RATE; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_SERV_CNTR_RATE" (
    "SNDR_SUBACCT" character varying(8) NOT NULL,
    "TOS" character varying(3) NOT NULL,
    "EFF_DATE" timestamp(3) without time zone NOT NULL,
    "INACT_DATE" timestamp(3) without time zone,
    "SERV_RATE" numeric(14,4) NOT NULL,
    "LAST_CHANGE_DATE" timestamp(3) without time zone,
    "LAST_CHANGE_ID" character varying(30)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_SERV_CNTR_RATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SERV_CNTR_RATE" ALTER COLUMN "SNDR_SUBACCT" OPTIONS (
    column_name 'SNDR_SUBACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SERV_CNTR_RATE" ALTER COLUMN "TOS" OPTIONS (
    column_name 'TOS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SERV_CNTR_RATE" ALTER COLUMN "EFF_DATE" OPTIONS (
    column_name 'EFF_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SERV_CNTR_RATE" ALTER COLUMN "INACT_DATE" OPTIONS (
    column_name 'INACT_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SERV_CNTR_RATE" ALTER COLUMN "SERV_RATE" OPTIONS (
    column_name 'SERV_RATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SERV_CNTR_RATE" ALTER COLUMN "LAST_CHANGE_DATE" OPTIONS (
    column_name 'LAST_CHANGE_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_SERV_CNTR_RATE" ALTER COLUMN "LAST_CHANGE_ID" OPTIONS (
    column_name 'LAST_CHANGE_ID'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_SERV_CNTR_RATE" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_SERV_CNTR_RATE"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_SERV_CNTR_RATE" TO writeaccess;

