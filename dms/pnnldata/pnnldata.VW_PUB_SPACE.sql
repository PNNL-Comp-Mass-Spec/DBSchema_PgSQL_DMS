--
-- Name: VW_PUB_SPACE; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_SPACE" (
    "SPACE_ID" character varying(8) NOT NULL,
    "FACILITY_ID" character varying(11) NOT NULL,
    "FLOOR_NO" character varying(3) NOT NULL,
    "ACTIVE_SW" character varying(1),
    "FIRE_ZONE" character varying(2),
    "IOPS_SPACE_SW" character varying(1) NOT NULL,
    "SPACE_NAME" character varying(25),
    "SPACE_STATUS_CD" character varying(2),
    "SQ_FEET" numeric(18,2),
    "TYPE_OF_SPACE_CD" character varying(3),
    "CATKEY" character varying(22),
    "CATEGORY_OF_SPACE_CD" character varying(4),
    "PHONE_NO" character varying(24),
    "LIFECYCLE_STATUS" character varying(15)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_SPACE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "SPACE_ID" OPTIONS (
    column_name 'SPACE_ID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "FACILITY_ID" OPTIONS (
    column_name 'FACILITY_ID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "FLOOR_NO" OPTIONS (
    column_name 'FLOOR_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "ACTIVE_SW" OPTIONS (
    column_name 'ACTIVE_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "FIRE_ZONE" OPTIONS (
    column_name 'FIRE_ZONE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "IOPS_SPACE_SW" OPTIONS (
    column_name 'IOPS_SPACE_SW'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "SPACE_NAME" OPTIONS (
    column_name 'SPACE_NAME'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "SPACE_STATUS_CD" OPTIONS (
    column_name 'SPACE_STATUS_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "SQ_FEET" OPTIONS (
    column_name 'SQ_FEET'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "TYPE_OF_SPACE_CD" OPTIONS (
    column_name 'TYPE_OF_SPACE_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "CATKEY" OPTIONS (
    column_name 'CATKEY'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "CATEGORY_OF_SPACE_CD" OPTIONS (
    column_name 'CATEGORY_OF_SPACE_CD'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "PHONE_NO" OPTIONS (
    column_name 'PHONE_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_SPACE" ALTER COLUMN "LIFECYCLE_STATUS" OPTIONS (
    column_name 'LIFECYCLE_STATUS'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_SPACE" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_SPACE"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_SPACE" TO writeaccess;

