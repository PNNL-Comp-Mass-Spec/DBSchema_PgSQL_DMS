--
-- Name: VW_PUB_RBAC_ROLE; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" (
    "ROLE_GUID" character varying(32) NOT NULL,
    "RBAC_APPL_GUID" character varying(32),
    "AUTH_PARENT_ROLE_GUID" character varying(32),
    "ROLE_NAME" character varying(64) NOT NULL,
    "ROLE_DESC" character varying(2000),
    "DISPLAY_NAME" character varying(255),
    "DELEGABLE_SW" character(1) NOT NULL,
    "EFF_DTM" timestamp(3) without time zone NOT NULL,
    "INACT_DTM" timestamp(3) without time zone,
    "ATTRIB_1" character varying(255),
    "ATTRIB_2" character varying(255),
    "ATTRIB_3" character varying(255),
    "ATTRIB_4" character varying(255),
    "ATTRIB_5" character varying(255),
    "CREATE_DTM" timestamp(3) without time zone NOT NULL,
    "MODIFIED_DTM" timestamp(3) without time zone NOT NULL,
    "MODIFIED_USN" bigint,
    "DW_ACQ_DATETIME" timestamp(3) without time zone NOT NULL,
    "DELETE_SW" character(1),
    "DELETE_DTM" timestamp(3) without time zone
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_RBAC_ROLE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "ROLE_GUID" OPTIONS (
    column_name 'ROLE_GUID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "RBAC_APPL_GUID" OPTIONS (
    column_name 'RBAC_APPL_GUID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "AUTH_PARENT_ROLE_GUID" OPTIONS (
    column_name 'AUTH_PARENT_ROLE_GUID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "ROLE_NAME" OPTIONS (
    column_name 'ROLE_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "ROLE_DESC" OPTIONS (
    column_name 'ROLE_DESC'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "DISPLAY_NAME" OPTIONS (
    column_name 'DISPLAY_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "DELEGABLE_SW" OPTIONS (
    column_name 'DELEGABLE_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "EFF_DTM" OPTIONS (
    column_name 'EFF_DTM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "INACT_DTM" OPTIONS (
    column_name 'INACT_DTM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "ATTRIB_1" OPTIONS (
    column_name 'ATTRIB_1'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "ATTRIB_2" OPTIONS (
    column_name 'ATTRIB_2'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "ATTRIB_3" OPTIONS (
    column_name 'ATTRIB_3'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "ATTRIB_4" OPTIONS (
    column_name 'ATTRIB_4'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "ATTRIB_5" OPTIONS (
    column_name 'ATTRIB_5'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "CREATE_DTM" OPTIONS (
    column_name 'CREATE_DTM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "MODIFIED_DTM" OPTIONS (
    column_name 'MODIFIED_DTM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "MODIFIED_USN" OPTIONS (
    column_name 'MODIFIED_USN'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "DW_ACQ_DATETIME" OPTIONS (
    column_name 'DW_ACQ_DATETIME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "DELETE_SW" OPTIONS (
    column_name 'DELETE_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" ALTER COLUMN "DELETE_DTM" OPTIONS (
    column_name 'DELETE_DTM'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_ROLE" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_RBAC_ROLE"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_RBAC_ROLE" TO writeaccess;

