--
-- Name: zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS" (
    "IP_ID" character varying(10) NOT NULL,
    "MASTER_ID" integer NOT NULL,
    "TITLE" character varying(100),
    "SUBMITTED_DATE" timestamp(3) without time zone NOT NULL,
    "IP_TYPE_DESC" character varying(10) NOT NULL,
    "WBS" character varying(13)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS'
);
ALTER FOREIGN TABLE pnnldata."zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS" ALTER COLUMN "IP_ID" OPTIONS (
    column_name 'IP_ID'
);
ALTER FOREIGN TABLE pnnldata."zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS" ALTER COLUMN "MASTER_ID" OPTIONS (
    column_name 'MASTER_ID'
);
ALTER FOREIGN TABLE pnnldata."zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS" ALTER COLUMN "TITLE" OPTIONS (
    column_name 'TITLE'
);
ALTER FOREIGN TABLE pnnldata."zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS" ALTER COLUMN "SUBMITTED_DATE" OPTIONS (
    column_name 'SUBMITTED_DATE'
);
ALTER FOREIGN TABLE pnnldata."zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS" ALTER COLUMN "IP_TYPE_DESC" OPTIONS (
    column_name 'IP_TYPE_DESC'
);
ALTER FOREIGN TABLE pnnldata."zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS" ALTER COLUMN "WBS" OPTIONS (
    column_name 'WBS'
);


ALTER FOREIGN TABLE pnnldata."zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS" OWNER TO d3l243;

--
-- Name: TABLE "zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."zzzVW_LDRD_DISCLOSURE_IP_VIA_WBS" TO writeaccess;

