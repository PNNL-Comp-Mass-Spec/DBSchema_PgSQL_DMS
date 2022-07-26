--
-- Name: VW_PUB_PORT_TO_LOCATION; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" (
    "SWITCH_DNS_NAME" character varying(63) NOT NULL,
    "MODULE_NO" integer NOT NULL,
    "PORT_NO" integer NOT NULL,
    "FACILITY_ID" character varying(11),
    "FLOOR_NO" character varying(3),
    "SPACE_ID" character varying(8),
    "OUTLET_ID" character varying(25),
    "OUTLET_JACK_ID" character varying(2),
    "DIRECT_SW" character varying(1) NOT NULL,
    "JACK_LOC_DESC" character varying(100),
    "SOURCE_DESC" character varying(50) NOT NULL,
    "SOURCE_DTM" timestamp(3) without time zone,
    "SOURCE_EMPLID" character varying(11),
    "ENTRY_DTM" timestamp(3) without time zone,
    "ENTRY_ACCOUNT" character varying(11),
    "ENTRY_EMPLID" character varying(11),
    "ENTRY_COMMENT" character varying(200)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_PORT_TO_LOCATION'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "SWITCH_DNS_NAME" OPTIONS (
    column_name 'SWITCH_DNS_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "MODULE_NO" OPTIONS (
    column_name 'MODULE_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "PORT_NO" OPTIONS (
    column_name 'PORT_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "FACILITY_ID" OPTIONS (
    column_name 'FACILITY_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "FLOOR_NO" OPTIONS (
    column_name 'FLOOR_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "SPACE_ID" OPTIONS (
    column_name 'SPACE_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "OUTLET_ID" OPTIONS (
    column_name 'OUTLET_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "OUTLET_JACK_ID" OPTIONS (
    column_name 'OUTLET_JACK_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "DIRECT_SW" OPTIONS (
    column_name 'DIRECT_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "JACK_LOC_DESC" OPTIONS (
    column_name 'JACK_LOC_DESC'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "SOURCE_DESC" OPTIONS (
    column_name 'SOURCE_DESC'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "SOURCE_DTM" OPTIONS (
    column_name 'SOURCE_DTM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "SOURCE_EMPLID" OPTIONS (
    column_name 'SOURCE_EMPLID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "ENTRY_DTM" OPTIONS (
    column_name 'ENTRY_DTM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "ENTRY_ACCOUNT" OPTIONS (
    column_name 'ENTRY_ACCOUNT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "ENTRY_EMPLID" OPTIONS (
    column_name 'ENTRY_EMPLID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" ALTER COLUMN "ENTRY_COMMENT" OPTIONS (
    column_name 'ENTRY_COMMENT'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_PORT_TO_LOCATION" OWNER TO d3l243;

