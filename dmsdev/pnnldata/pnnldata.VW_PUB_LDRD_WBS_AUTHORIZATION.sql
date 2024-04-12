--
-- Name: VW_PUB_LDRD_WBS_AUTHORIZATION; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_AUTHORIZATION" (
    "SUBACCT" character varying(6),
    "WBS_ID" character varying(255) NOT NULL,
    "AUTH_AMT" numeric(12,0) NOT NULL
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_LDRD_WBS_AUTHORIZATION'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_AUTHORIZATION" ALTER COLUMN "SUBACCT" OPTIONS (
    column_name 'SUBACCT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_AUTHORIZATION" ALTER COLUMN "WBS_ID" OPTIONS (
    column_name 'WBS_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_AUTHORIZATION" ALTER COLUMN "AUTH_AMT" OPTIONS (
    column_name 'AUTH_AMT'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_LDRD_WBS_AUTHORIZATION" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_LDRD_WBS_AUTHORIZATION"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_LDRD_WBS_AUTHORIZATION" TO writeaccess;

