--
-- Name: VW_PUB_STATE; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_STATE" (
    "COUNTRY_ID" character varying(4) NOT NULL,
    "STATE_CD" character varying(8) NOT NULL,
    "STATE_NAME" character varying(25),
    "STATE_LOC" character varying(4)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_STATE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_STATE" ALTER COLUMN "COUNTRY_ID" OPTIONS (
    column_name 'COUNTRY_ID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_STATE" ALTER COLUMN "STATE_CD" OPTIONS (
    column_name 'STATE_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_STATE" ALTER COLUMN "STATE_NAME" OPTIONS (
    column_name 'STATE_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_STATE" ALTER COLUMN "STATE_LOC" OPTIONS (
    column_name 'STATE_LOC'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_STATE" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_STATE"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_STATE" TO writeaccess;

