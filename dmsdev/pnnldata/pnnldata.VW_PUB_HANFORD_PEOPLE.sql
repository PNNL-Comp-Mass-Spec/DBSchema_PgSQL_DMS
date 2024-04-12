--
-- Name: VW_PUB_HANFORD_PEOPLE; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" (
    "HANFORD_ID" character varying(7) NOT NULL,
    "ACTIVE_SW" character varying(1) NOT NULL,
    "EMPLOYED_BY_HCID" character varying(5),
    "ASSIGNED_TO_HCID" character varying(5),
    "NAME" character varying(50),
    "NAME_FM" character varying(50),
    "FIRST_NAME" character varying(30),
    "LAST_NAME" character varying(30) NOT NULL,
    "MIDDLE_INITIAL" character varying(1),
    "NAME_SUFFIX" character varying(3),
    "PREF_FIRST_NAME" character varying(30),
    "BADGE_ACTIVE_DATE" timestamp(3) without time zone,
    "BADGE_INACT_DATE" timestamp(3) without time zone,
    "CLASS_TYPE" character varying(1),
    "COST_CD" character varying(10),
    "HANF_ORG_ID" character varying(10),
    "INITIALS" character varying(2),
    "HANF_PAY_NO" character varying(7),
    "PAY_KEY_CD" integer,
    "BLD_NO" character varying(11),
    "ROOM_NO" character varying(5),
    "MSIN" character varying(8),
    "AREA" character varying(6),
    "SUITE" character varying(5),
    "FAX_NO" character varying(12),
    "PHONE_NO" character varying(12),
    "PAGER_NO" character varying(12),
    "INTERNET_EMAIL_ADDRESS" character varying(64),
    "PER_LAST_CHANGE_DATE" integer,
    "EMP_LAST_CHANGE_DATE" integer,
    "WORK_LAST_CHANGE_DATE" integer,
    "PAGER_LAST_CHANGE_DATE" integer
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_HANFORD_PEOPLE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "HANFORD_ID" OPTIONS (
    column_name 'HANFORD_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "ACTIVE_SW" OPTIONS (
    column_name 'ACTIVE_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "EMPLOYED_BY_HCID" OPTIONS (
    column_name 'EMPLOYED_BY_HCID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "ASSIGNED_TO_HCID" OPTIONS (
    column_name 'ASSIGNED_TO_HCID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "NAME" OPTIONS (
    column_name 'NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "NAME_FM" OPTIONS (
    column_name 'NAME_FM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "FIRST_NAME" OPTIONS (
    column_name 'FIRST_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "LAST_NAME" OPTIONS (
    column_name 'LAST_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "MIDDLE_INITIAL" OPTIONS (
    column_name 'MIDDLE_INITIAL'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "NAME_SUFFIX" OPTIONS (
    column_name 'NAME_SUFFIX'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "PREF_FIRST_NAME" OPTIONS (
    column_name 'PREF_FIRST_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "BADGE_ACTIVE_DATE" OPTIONS (
    column_name 'BADGE_ACTIVE_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "BADGE_INACT_DATE" OPTIONS (
    column_name 'BADGE_INACT_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "CLASS_TYPE" OPTIONS (
    column_name 'CLASS_TYPE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "COST_CD" OPTIONS (
    column_name 'COST_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "HANF_ORG_ID" OPTIONS (
    column_name 'HANF_ORG_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "INITIALS" OPTIONS (
    column_name 'INITIALS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "HANF_PAY_NO" OPTIONS (
    column_name 'HANF_PAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "PAY_KEY_CD" OPTIONS (
    column_name 'PAY_KEY_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "BLD_NO" OPTIONS (
    column_name 'BLD_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "ROOM_NO" OPTIONS (
    column_name 'ROOM_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "MSIN" OPTIONS (
    column_name 'MSIN'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "AREA" OPTIONS (
    column_name 'AREA'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "SUITE" OPTIONS (
    column_name 'SUITE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "FAX_NO" OPTIONS (
    column_name 'FAX_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "PHONE_NO" OPTIONS (
    column_name 'PHONE_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "PAGER_NO" OPTIONS (
    column_name 'PAGER_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "INTERNET_EMAIL_ADDRESS" OPTIONS (
    column_name 'INTERNET_EMAIL_ADDRESS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "PER_LAST_CHANGE_DATE" OPTIONS (
    column_name 'PER_LAST_CHANGE_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "EMP_LAST_CHANGE_DATE" OPTIONS (
    column_name 'EMP_LAST_CHANGE_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "WORK_LAST_CHANGE_DATE" OPTIONS (
    column_name 'WORK_LAST_CHANGE_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" ALTER COLUMN "PAGER_LAST_CHANGE_DATE" OPTIONS (
    column_name 'PAGER_LAST_CHANGE_DATE'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_HANFORD_PEOPLE"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_HANFORD_PEOPLE" TO writeaccess;

