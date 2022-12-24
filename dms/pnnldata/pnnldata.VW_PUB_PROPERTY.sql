--
-- Name: VW_PUB_PROPERTY; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" (
    "PROPTY_NO" character varying(9) NOT NULL,
    "PRIOR_PROPTY_NO" character varying(9),
    "ACQ_DOCUMENT" character varying(13),
    "ADP_STUDY_NO" character varying(9),
    "ADP_SYS_NO" character varying(2),
    "ADP_WORD_PROC_IND" character varying(1),
    "CLNT_CD" character varying(4),
    "CLNT_CONT_NO" character varying(20),
    "CLNT_PROPTY_NO" character varying(9),
    "CLNT_SUBCONTR_SW" character varying(1),
    "COMMODITY_CD" character varying(13),
    "CURRENT_PROJ_NO" character varying(8),
    "DELV_DATE" timestamp(3) without time zone,
    "ENT" character varying(1),
    "EQPT_CAT_CD" character varying(4),
    "EQPT_CNTR" character varying(6),
    "EQPT_POSITION_NO" character varying(10),
    "EQPT_SIZE_CAPCTY" character varying(13),
    "EQPT_TYPE" character varying(24),
    "FIRE_CD" character varying(1),
    "MFG_MODEL" character varying(16),
    "MFG_NAME" character varying(24),
    "NRC_PROJ_NO" character varying(5),
    "PNL_EQPT_CAT" character varying(5),
    "PRIOR_EQPT_CNTR" character varying(6),
    "PRIOR_EQPT_CNTR_DATE" timestamp(3) without time zone,
    "PRIOR_PNL_EQPT_CAT" character varying(5),
    "PRIOR_PNL_EQPT_CAT_DATE" timestamp(3) without time zone,
    "PROCR_AUTHN" character varying(11),
    "PROCR_CHARGE_CD" character varying(6),
    "PROPTY_DESC" character varying(20),
    "PROPTY_NAME" character varying(24),
    "PROPTY_TAX_TYPE" character varying(5),
    "QTY" character varying(10),
    "RETR_DATE" timestamp(3) without time zone,
    "SENSTV_SW" character varying(1),
    "SERIAL_NO" character varying(15),
    "SUBCONT_COMPLETION_DATE" timestamp(3) without time zone,
    "SUBCONT_NO" character varying(9),
    "SYSTEM" character varying(20),
    "TAX_IND" character varying(1),
    "TRNSF_FILE_SW" character varying(1),
    "DEL_IND" character varying(1),
    "MISC_FLG" character varying(1),
    "RECORD_SRC" character varying(20),
    "LAST_CHANGE_ID" character varying(6),
    "LAST_CHANGE_DATE" timestamp(3) without time zone,
    "HIGH_RISK_SW" character varying(1),
    "RASD_EXCL_SW" character varying(1)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'VW_PUB_PROPERTY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PROPTY_NO" OPTIONS (
    column_name 'PROPTY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PRIOR_PROPTY_NO" OPTIONS (
    column_name 'PRIOR_PROPTY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "ACQ_DOCUMENT" OPTIONS (
    column_name 'ACQ_DOCUMENT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "ADP_STUDY_NO" OPTIONS (
    column_name 'ADP_STUDY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "ADP_SYS_NO" OPTIONS (
    column_name 'ADP_SYS_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "ADP_WORD_PROC_IND" OPTIONS (
    column_name 'ADP_WORD_PROC_IND'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "CLNT_CD" OPTIONS (
    column_name 'CLNT_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "CLNT_CONT_NO" OPTIONS (
    column_name 'CLNT_CONT_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "CLNT_PROPTY_NO" OPTIONS (
    column_name 'CLNT_PROPTY_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "CLNT_SUBCONTR_SW" OPTIONS (
    column_name 'CLNT_SUBCONTR_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "COMMODITY_CD" OPTIONS (
    column_name 'COMMODITY_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "CURRENT_PROJ_NO" OPTIONS (
    column_name 'CURRENT_PROJ_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "DELV_DATE" OPTIONS (
    column_name 'DELV_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "ENT" OPTIONS (
    column_name 'ENT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "EQPT_CAT_CD" OPTIONS (
    column_name 'EQPT_CAT_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "EQPT_CNTR" OPTIONS (
    column_name 'EQPT_CNTR'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "EQPT_POSITION_NO" OPTIONS (
    column_name 'EQPT_POSITION_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "EQPT_SIZE_CAPCTY" OPTIONS (
    column_name 'EQPT_SIZE_CAPCTY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "EQPT_TYPE" OPTIONS (
    column_name 'EQPT_TYPE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "FIRE_CD" OPTIONS (
    column_name 'FIRE_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "MFG_MODEL" OPTIONS (
    column_name 'MFG_MODEL'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "MFG_NAME" OPTIONS (
    column_name 'MFG_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "NRC_PROJ_NO" OPTIONS (
    column_name 'NRC_PROJ_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PNL_EQPT_CAT" OPTIONS (
    column_name 'PNL_EQPT_CAT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PRIOR_EQPT_CNTR" OPTIONS (
    column_name 'PRIOR_EQPT_CNTR'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PRIOR_EQPT_CNTR_DATE" OPTIONS (
    column_name 'PRIOR_EQPT_CNTR_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PRIOR_PNL_EQPT_CAT" OPTIONS (
    column_name 'PRIOR_PNL_EQPT_CAT'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PRIOR_PNL_EQPT_CAT_DATE" OPTIONS (
    column_name 'PRIOR_PNL_EQPT_CAT_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PROCR_AUTHN" OPTIONS (
    column_name 'PROCR_AUTHN'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PROCR_CHARGE_CD" OPTIONS (
    column_name 'PROCR_CHARGE_CD'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PROPTY_DESC" OPTIONS (
    column_name 'PROPTY_DESC'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PROPTY_NAME" OPTIONS (
    column_name 'PROPTY_NAME'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "PROPTY_TAX_TYPE" OPTIONS (
    column_name 'PROPTY_TAX_TYPE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "QTY" OPTIONS (
    column_name 'QTY'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "RETR_DATE" OPTIONS (
    column_name 'RETR_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "SENSTV_SW" OPTIONS (
    column_name 'SENSTV_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "SERIAL_NO" OPTIONS (
    column_name 'SERIAL_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "SUBCONT_COMPLETION_DATE" OPTIONS (
    column_name 'SUBCONT_COMPLETION_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "SUBCONT_NO" OPTIONS (
    column_name 'SUBCONT_NO'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "SYSTEM" OPTIONS (
    column_name 'SYSTEM'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "TAX_IND" OPTIONS (
    column_name 'TAX_IND'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "TRNSF_FILE_SW" OPTIONS (
    column_name 'TRNSF_FILE_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "DEL_IND" OPTIONS (
    column_name 'DEL_IND'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "MISC_FLG" OPTIONS (
    column_name 'MISC_FLG'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "RECORD_SRC" OPTIONS (
    column_name 'RECORD_SRC'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "LAST_CHANGE_ID" OPTIONS (
    column_name 'LAST_CHANGE_ID'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "LAST_CHANGE_DATE" OPTIONS (
    column_name 'LAST_CHANGE_DATE'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "HIGH_RISK_SW" OPTIONS (
    column_name 'HIGH_RISK_SW'
);
ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" ALTER COLUMN "RASD_EXCL_SW" OPTIONS (
    column_name 'RASD_EXCL_SW'
);


ALTER FOREIGN TABLE pnnldata."VW_PUB_PROPERTY" OWNER TO d3l243;

--
-- Name: TABLE "VW_PUB_PROPERTY"; Type: ACL; Schema: pnnldata; Owner: d3l243
--

GRANT SELECT ON TABLE pnnldata."VW_PUB_PROPERTY" TO writeaccess;

