--
-- Name: VW_PUB_FACILITY_CSM; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" (
    "FACILITY_ID" character varying(11) NOT NULL,
    "SPACE_ID" character varying(8) NOT NULL,
    "FLOOR_NO" character varying(3) NOT NULL,
    "CSM_TYPE" character varying(24) NOT NULL,
    "CSM_EMPLID" character varying(10),
    "CSM_HID" character varying(7),
    "CSM_NAME" character varying(50),
    "CSM_WORK_PHONE" character varying(24),
    "CATKEY" character varying(22) NOT NULL
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_FACILITY_CSM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" ALTER COLUMN "FACILITY_ID" OPTIONS (
    column_name 'FACILITY_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" ALTER COLUMN "SPACE_ID" OPTIONS (
    column_name 'SPACE_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" ALTER COLUMN "FLOOR_NO" OPTIONS (
    column_name 'FLOOR_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" ALTER COLUMN "CSM_TYPE" OPTIONS (
    column_name 'CSM_TYPE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" ALTER COLUMN "CSM_EMPLID" OPTIONS (
    column_name 'CSM_EMPLID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" ALTER COLUMN "CSM_HID" OPTIONS (
    column_name 'CSM_HID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" ALTER COLUMN "CSM_NAME" OPTIONS (
    column_name 'CSM_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" ALTER COLUMN "CSM_WORK_PHONE" OPTIONS (
    column_name 'CSM_WORK_PHONE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" ALTER COLUMN "CATKEY" OPTIONS (
    column_name 'CATKEY'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_FACILITY_CSM" OWNER TO d3l243;

