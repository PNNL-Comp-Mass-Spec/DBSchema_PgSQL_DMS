--
-- Name: VW_PUB_FIS_ROOM_MAPPING; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_FIS_ROOM_MAPPING" (
    "FIS_FACILITY_ID" character varying(11) NOT NULL,
    "FIS_SPACE_ID" character varying(8) NOT NULL,
    "BLDG_NO" character varying(50) NOT NULL,
    "ROOM_NO" character varying(20) NOT NULL
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_FIS_ROOM_MAPPING'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FIS_ROOM_MAPPING" ALTER COLUMN "FIS_FACILITY_ID" OPTIONS (
    column_name 'FIS_FACILITY_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FIS_ROOM_MAPPING" ALTER COLUMN "FIS_SPACE_ID" OPTIONS (
    column_name 'FIS_SPACE_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FIS_ROOM_MAPPING" ALTER COLUMN "BLDG_NO" OPTIONS (
    column_name 'BLDG_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_FIS_ROOM_MAPPING" ALTER COLUMN "ROOM_NO" OPTIONS (
    column_name 'ROOM_NO'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_FIS_ROOM_MAPPING" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_FIS_ROOM_MAPPING"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_FIS_ROOM_MAPPING" TO writeaccess;

