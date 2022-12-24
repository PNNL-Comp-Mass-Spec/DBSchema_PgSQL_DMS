--
-- Name: VW_PUB_MACHINES; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_MACHINES" (
    "CPU_PROPERTY" character varying(9) NOT NULL,
    "CPU_SERIAL_NUMBER" character varying(80),
    "PAY_NO" character varying(10),
    "ADP_NUMBER" character varying(8),
    "MANUFACTURER" character varying(64),
    "MODEL" character varying(64),
    "MODEL_DESCRIPTION" character varying(255),
    "U_NAME" character varying(64),
    "ORG_CD" character varying(6),
    "LAST_INVENTORY_DATE" timestamp(3) without time zone,
    "LAST_MANUAL_ENTRY_DATE" timestamp(3) without time zone,
    "LAST_DYNAMIC_ENTRY_DATE" timestamp(3) without time zone,
    "COMMENTS" character varying(255),
    "TIMESTAMP" bytea
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_MACHINES'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "CPU_PROPERTY" OPTIONS (
    column_name 'CPU_PROPERTY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "CPU_SERIAL_NUMBER" OPTIONS (
    column_name 'CPU_SERIAL_NUMBER'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "PAY_NO" OPTIONS (
    column_name 'PAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "ADP_NUMBER" OPTIONS (
    column_name 'ADP_NUMBER'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "MANUFACTURER" OPTIONS (
    column_name 'MANUFACTURER'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "MODEL" OPTIONS (
    column_name 'MODEL'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "MODEL_DESCRIPTION" OPTIONS (
    column_name 'MODEL_DESCRIPTION'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "U_NAME" OPTIONS (
    column_name 'U_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "ORG_CD" OPTIONS (
    column_name 'ORG_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "LAST_INVENTORY_DATE" OPTIONS (
    column_name 'LAST_INVENTORY_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "LAST_MANUAL_ENTRY_DATE" OPTIONS (
    column_name 'LAST_MANUAL_ENTRY_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "LAST_DYNAMIC_ENTRY_DATE" OPTIONS (
    column_name 'LAST_DYNAMIC_ENTRY_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "COMMENTS" OPTIONS (
    column_name 'COMMENTS'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" ALTER COLUMN "TIMESTAMP" OPTIONS (
    column_name 'TIMESTAMP'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_MACHINES" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_MACHINES"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_MACHINES" TO writeaccess;

