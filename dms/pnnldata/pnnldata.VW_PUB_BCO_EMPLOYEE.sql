--
-- Name: VW_PUB_BCO_EMPLOYEE; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_BCO_EMPLOYEE" (
    "EMPLID" character varying(11) NOT NULL,
    "LOCATION" character varying(10),
    "BLD_NO" character varying(11),
    "ROOM_NO" character varying(30),
    "FLOOR" character varying(10),
    "MSIN" character varying(28),
    "FAX_NO" character varying(24),
    "WORK_PHONE" character varying(24),
    "INTERNET_EMAIL_ADDRESS" character varying(64),
    "COMPANY" character varying(3),
    "NAME" character varying(50)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_BCO_EMPLOYEE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "EMPLID" OPTIONS (
    column_name 'EMPLID'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "LOCATION" OPTIONS (
    column_name 'LOCATION'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "BLD_NO" OPTIONS (
    column_name 'BLD_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "ROOM_NO" OPTIONS (
    column_name 'ROOM_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "FLOOR" OPTIONS (
    column_name 'FLOOR'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "MSIN" OPTIONS (
    column_name 'MSIN'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "FAX_NO" OPTIONS (
    column_name 'FAX_NO'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "WORK_PHONE" OPTIONS (
    column_name 'WORK_PHONE'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "INTERNET_EMAIL_ADDRESS" OPTIONS (
    column_name 'INTERNET_EMAIL_ADDRESS'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "COMPANY" OPTIONS (
    column_name 'COMPANY'
);
ALTER FOREIGN TABLE ONLY pnnldata."VW_PUB_BCO_EMPLOYEE" ALTER COLUMN "NAME" OPTIONS (
    column_name 'NAME'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_BCO_EMPLOYEE" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_BCO_EMPLOYEE"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_BCO_EMPLOYEE" TO writeaccess;

