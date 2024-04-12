--
-- Name: VW_PUB_DATE_DIM; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" (
    "DATE_VALUE" timestamp(3) without time zone NOT NULL,
    "WEEK_DAY_NO" smallint NOT NULL,
    "WEEK_DAY_NAME" character varying(9) NOT NULL,
    "WEEKEND_FLG" character(1) NOT NULL,
    "HOLIDAY_FLG" character(1),
    "HOLIDAY_NAME" character varying(30),
    "WORKING_DAY_FLG" character(1),
    "CY_NO" smallint NOT NULL,
    "CY_QUARTER_NO" smallint NOT NULL,
    "CY_MONTH_NO" smallint NOT NULL,
    "CY_DAY_NO" smallint NOT NULL,
    "CY_WRK_DAY_NO" smallint,
    "CM_DAY_NO" smallint NOT NULL,
    "CM_WRK_DAY_NO" integer,
    "CY_MONTH_NAME" character varying(9) NOT NULL,
    "CY_MONTH_ABREV" character(3) NOT NULL,
    "FY_NO" smallint NOT NULL,
    "FY_QUARTER_NO" smallint,
    "FY_MONTH_NO" smallint,
    "FY_DAY_NO" smallint NOT NULL,
    "FY_WRK_DAY_NO" smallint,
    "FM_DAY_NO" smallint,
    "FM_WRK_DAY_NO" smallint,
    "FY_MONTH_NAME" character varying(9),
    "FY_MONTH_ABREV" character(3),
    "ETR_PERIOD_NO" integer NOT NULL,
    "IPAP_DATE_STR" character(6) NOT NULL,
    "IPAP_DATE_NO" numeric(6,0) NOT NULL,
    "RPT_DATE" character(6)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_DATE_DIM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "DATE_VALUE" OPTIONS (
    column_name 'DATE_VALUE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "WEEK_DAY_NO" OPTIONS (
    column_name 'WEEK_DAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "WEEK_DAY_NAME" OPTIONS (
    column_name 'WEEK_DAY_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "WEEKEND_FLG" OPTIONS (
    column_name 'WEEKEND_FLG'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "HOLIDAY_FLG" OPTIONS (
    column_name 'HOLIDAY_FLG'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "HOLIDAY_NAME" OPTIONS (
    column_name 'HOLIDAY_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "WORKING_DAY_FLG" OPTIONS (
    column_name 'WORKING_DAY_FLG'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "CY_NO" OPTIONS (
    column_name 'CY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "CY_QUARTER_NO" OPTIONS (
    column_name 'CY_QUARTER_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "CY_MONTH_NO" OPTIONS (
    column_name 'CY_MONTH_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "CY_DAY_NO" OPTIONS (
    column_name 'CY_DAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "CY_WRK_DAY_NO" OPTIONS (
    column_name 'CY_WRK_DAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "CM_DAY_NO" OPTIONS (
    column_name 'CM_DAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "CM_WRK_DAY_NO" OPTIONS (
    column_name 'CM_WRK_DAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "CY_MONTH_NAME" OPTIONS (
    column_name 'CY_MONTH_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "CY_MONTH_ABREV" OPTIONS (
    column_name 'CY_MONTH_ABREV'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "FY_NO" OPTIONS (
    column_name 'FY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "FY_QUARTER_NO" OPTIONS (
    column_name 'FY_QUARTER_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "FY_MONTH_NO" OPTIONS (
    column_name 'FY_MONTH_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "FY_DAY_NO" OPTIONS (
    column_name 'FY_DAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "FY_WRK_DAY_NO" OPTIONS (
    column_name 'FY_WRK_DAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "FM_DAY_NO" OPTIONS (
    column_name 'FM_DAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "FM_WRK_DAY_NO" OPTIONS (
    column_name 'FM_WRK_DAY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "FY_MONTH_NAME" OPTIONS (
    column_name 'FY_MONTH_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "FY_MONTH_ABREV" OPTIONS (
    column_name 'FY_MONTH_ABREV'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "ETR_PERIOD_NO" OPTIONS (
    column_name 'ETR_PERIOD_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "IPAP_DATE_STR" OPTIONS (
    column_name 'IPAP_DATE_STR'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "IPAP_DATE_NO" OPTIONS (
    column_name 'IPAP_DATE_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" ALTER COLUMN "RPT_DATE" OPTIONS (
    column_name 'RPT_DATE'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_DATE_DIM" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_DATE_DIM"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_DATE_DIM" TO writeaccess;

