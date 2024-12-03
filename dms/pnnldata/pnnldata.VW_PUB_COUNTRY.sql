--
-- Name: VW_PUB_COUNTRY; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_COUNTRY" (
    "CTRY_CD" character varying(2) NOT NULL,
    "CTRY_NAME" character varying(50) NOT NULL,
    "FIPS_CTRY_CD" character varying(3) NOT NULL,
    "OPEN_CTRY_SW" character varying(1) NOT NULL,
    "PRIMARY_REGION_CD" character varying(4)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_COUNTRY'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_COUNTRY" ALTER COLUMN "CTRY_CD" OPTIONS (
    column_name 'CTRY_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_COUNTRY" ALTER COLUMN "CTRY_NAME" OPTIONS (
    column_name 'CTRY_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_COUNTRY" ALTER COLUMN "FIPS_CTRY_CD" OPTIONS (
    column_name 'FIPS_CTRY_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_COUNTRY" ALTER COLUMN "OPEN_CTRY_SW" OPTIONS (
    column_name 'OPEN_CTRY_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_COUNTRY" ALTER COLUMN "PRIMARY_REGION_CD" OPTIONS (
    column_name 'PRIMARY_REGION_CD'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_COUNTRY" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_COUNTRY"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_COUNTRY" TO writeaccess;

