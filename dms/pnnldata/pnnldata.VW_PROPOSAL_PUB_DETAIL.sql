--
-- Name: VW_PROPOSAL_PUB_DETAIL; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PROPOSAL_PUB_DETAIL" (
    "LDRD_PROPOSAL_KEY" integer NOT NULL,
    "PUBLICATION_ID" integer NOT NULL,
    "CITATION_TXT" text,
    "PNNL_CLEARANCE_NO" character varying(40),
    "PRODUCT_ID" numeric(10,0),
    "PRODUCT_NAME" character varying(500),
    "PRODUCT_PUB_CY_NO" character varying(4),
    "PRODUCT_PUB_FY_NO" character varying(4),
    "PRODUCT_TYPE_NAME" character varying(50),
    "LEGACY_PUB_TYPE_ID" integer,
    "REFEREED_SW" character(1),
    "PRODUCT_CD" character varying(3)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PROPOSAL_PUB_DETAIL'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "LDRD_PROPOSAL_KEY" OPTIONS (
    column_name 'LDRD_PROPOSAL_KEY'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "PUBLICATION_ID" OPTIONS (
    column_name 'PUBLICATION_ID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "CITATION_TXT" OPTIONS (
    column_name 'CITATION_TXT'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "PNNL_CLEARANCE_NO" OPTIONS (
    column_name 'PNNL_CLEARANCE_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "PRODUCT_ID" OPTIONS (
    column_name 'PRODUCT_ID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "PRODUCT_NAME" OPTIONS (
    column_name 'PRODUCT_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "PRODUCT_PUB_CY_NO" OPTIONS (
    column_name 'PRODUCT_PUB_CY_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "PRODUCT_PUB_FY_NO" OPTIONS (
    column_name 'PRODUCT_PUB_FY_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "PRODUCT_TYPE_NAME" OPTIONS (
    column_name 'PRODUCT_TYPE_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "LEGACY_PUB_TYPE_ID" OPTIONS (
    column_name 'LEGACY_PUB_TYPE_ID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "REFEREED_SW" OPTIONS (
    column_name 'REFEREED_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PROPOSAL_PUB_DETAIL" ALTER COLUMN "PRODUCT_CD" OPTIONS (
    column_name 'PRODUCT_CD'
);


ALTER FOREIGN TABLE pnnldata."VW_PROPOSAL_PUB_DETAIL" OWNER TO d3l243;

--
-- Name: TABLE "VW_PROPOSAL_PUB_DETAIL"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PROPOSAL_PUB_DETAIL" TO writeaccess;

