--
-- Name: VW_PUB_PROPERTY_OFFSITE; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" (
    "CITY" character varying(20),
    "COMPANY_NAME" character varying(20),
    "COUNTRY_CD" character varying(3),
    "CURRENT_OPC_NO" character varying(6),
    "DEL_IND" character varying(1),
    "EST_RETN_DATE" timestamp(3) without time zone,
    "INDIV_NAME" character varying(20),
    "LAST_CHANGE_DATE" timestamp(3) without time zone,
    "LAST_CHANGE_ID" character varying(6),
    "MISC_FLG" character varying(1),
    "OFFST_ADDR" character varying(30),
    "PROPTY_NO" character varying(9) NOT NULL,
    "RECORD_SRC" character varying(20),
    "STATE_CD" character varying(2),
    "DW_ACQ_DATETIME" timestamp(3) without time zone NOT NULL
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_PROPERTY_OFFSITE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "CITY" OPTIONS (
    column_name 'CITY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "COMPANY_NAME" OPTIONS (
    column_name 'COMPANY_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "COUNTRY_CD" OPTIONS (
    column_name 'COUNTRY_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "CURRENT_OPC_NO" OPTIONS (
    column_name 'CURRENT_OPC_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "DEL_IND" OPTIONS (
    column_name 'DEL_IND'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "EST_RETN_DATE" OPTIONS (
    column_name 'EST_RETN_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "INDIV_NAME" OPTIONS (
    column_name 'INDIV_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "LAST_CHANGE_DATE" OPTIONS (
    column_name 'LAST_CHANGE_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "LAST_CHANGE_ID" OPTIONS (
    column_name 'LAST_CHANGE_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "MISC_FLG" OPTIONS (
    column_name 'MISC_FLG'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "OFFST_ADDR" OPTIONS (
    column_name 'OFFST_ADDR'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "PROPTY_NO" OPTIONS (
    column_name 'PROPTY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "RECORD_SRC" OPTIONS (
    column_name 'RECORD_SRC'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "STATE_CD" OPTIONS (
    column_name 'STATE_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" ALTER COLUMN "DW_ACQ_DATETIME" OPTIONS (
    column_name 'DW_ACQ_DATETIME'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_PROPERTY_OFFSITE"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_PROPERTY_OFFSITE" TO writeaccess;

