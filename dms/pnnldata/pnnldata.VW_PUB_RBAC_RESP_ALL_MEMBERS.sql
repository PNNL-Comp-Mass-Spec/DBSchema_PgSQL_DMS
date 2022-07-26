--
-- Name: VW_PUB_RBAC_RESP_ALL_MEMBERS; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_RBAC_RESP_ALL_MEMBERS" (
    "RESPONSIBLE_ROLE_NAME" character varying(64) NOT NULL,
    "RESPONSIBLE_FOR_ROLE_NAME" character varying(64) NOT NULL,
    "CHILD_ROLE_NAME" character varying(64) NOT NULL,
    "EMPLID" character varying(11),
    "HANFORD_ID" character varying(7),
    "DIRECT_MEMBER_SW" character varying(1) NOT NULL,
    "USER_MEMBERSHIP_TYPE_CD" character(1) NOT NULL
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_RBAC_RESP_ALL_MEMBERS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_RESP_ALL_MEMBERS" ALTER COLUMN "RESPONSIBLE_ROLE_NAME" OPTIONS (
    column_name 'RESPONSIBLE_ROLE_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_RESP_ALL_MEMBERS" ALTER COLUMN "RESPONSIBLE_FOR_ROLE_NAME" OPTIONS (
    column_name 'RESPONSIBLE_FOR_ROLE_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_RESP_ALL_MEMBERS" ALTER COLUMN "CHILD_ROLE_NAME" OPTIONS (
    column_name 'CHILD_ROLE_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_RESP_ALL_MEMBERS" ALTER COLUMN "EMPLID" OPTIONS (
    column_name 'EMPLID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_RESP_ALL_MEMBERS" ALTER COLUMN "HANFORD_ID" OPTIONS (
    column_name 'HANFORD_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_RESP_ALL_MEMBERS" ALTER COLUMN "DIRECT_MEMBER_SW" OPTIONS (
    column_name 'DIRECT_MEMBER_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_RESP_ALL_MEMBERS" ALTER COLUMN "USER_MEMBERSHIP_TYPE_CD" OPTIONS (
    column_name 'USER_MEMBERSHIP_TYPE_CD'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_RBAC_RESP_ALL_MEMBERS" OWNER TO d3l243;

