--
-- Name: vw_pub_pnnl_associate; Type: FOREIGN TABLE; Schema: pnnldata; Owner: d3l243
--

CREATE FOREIGN TABLE pnnldata.vw_pub_pnnl_associate (
    "HANFORD_ID" character varying(7) NOT NULL,
    "ASSIGNED_TO_HCID" character varying(5),
    "BADGE_ACTIVE_DATE" timestamp(3) without time zone,
    "BADGE_ACTIVE_SW" character varying(1) NOT NULL,
    "CLASS_TYPE" character varying(1),
    "CONTACT_ADDRESS1" character varying(35),
    "CONTACT_ADDRESS2" character varying(35),
    "CONTACT_ADDRESS3" character varying(35),
    "CONTACT_ADDRESS4" character varying(35),
    "CONTACT_BLD_NO" character varying(11),
    "CONTACT_CITY" character varying(30),
    "CONTACT_COUNTRY" character varying(3),
    "CONTACT_COUNTY" character varying(30),
    "CONTACT_LOCATION" character varying(10),
    "CONTACT_MSIN" character varying(8),
    "CONTACT_PHON_CNTRY" character varying(3),
    "CONTACT_PHONE" character varying(12),
    "CONTACT_ROOM_NO" character varying(5),
    "CONTACT_STATE" character varying(6),
    "CONTACT_ZIP" character varying(10),
    "DEPTID" character varying(10),
    "EMPLOYED_BY_HCID" character varying(5),
    "ENTER_DATE" timestamp(3) without time zone NOT NULL,
    "FIRST_NAME" character varying(30) NOT NULL,
    "INTERNET_ADDRESS" character varying(50),
    "LAST_MOD_DATE" timestamp(3) without time zone NOT NULL,
    "LAST_MOD_ID" character varying(8) NOT NULL,
    "LAST_NAME" character varying(30) NOT NULL,
    "MIDDLE_NAME" character varying(30),
    "NAME" character varying(50),
    "NAME_SUFFIX" character varying(3),
    "PAY_NO" character varying(5),
    "PNL_ACT_DATE" timestamp(3) without time zone,
    "PNL_INACT_DATE" timestamp(3) without time zone,
    "PNL_MAINTAINED_SW" character varying(1) NOT NULL,
    "POPFON_SW" character varying(1) NOT NULL,
    "PREF_FIRST_NAME" character varying(30),
    "WORK_ADDRESS1" character varying(35),
    "WORK_ADDRESS2" character varying(35),
    "WORK_ADDRESS3" character varying(35),
    "WORK_ADDRESS4" character varying(35),
    "WORK_BLD_NO" character varying(11),
    "WORK_CITY" character varying(30),
    "WORK_COUNTRY" character varying(3),
    "WORK_COUNTY" character varying(30),
    "WORK_LOCATION" character varying(10),
    "WORK_MSIN" character varying(8),
    "WORK_PHON_CNTRY" character varying(3),
    "WORK_PHONE" character varying(12),
    "WORK_ROOM_NO" character varying(5),
    "WORK_STATE" character varying(6),
    "WORK_ZIP" character varying(10),
    "PNL_NELS_POI_TYPE" character varying(6),
    "PERSON_TYPE" character varying(5),
    "PERSON_TYPE_DESC" character varying(30),
    "PERSON_SUB_TYPE" character varying(6),
    "PERSON_SUB_TYPE_DESC" character varying(60)
)
SERVER op_warehouse_fdw
OPTIONS (
    schema_name 'dbo',
    table_name 'vw_pub_pnnl_associate'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "HANFORD_ID" OPTIONS (
    column_name 'HANFORD_ID'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "ASSIGNED_TO_HCID" OPTIONS (
    column_name 'ASSIGNED_TO_HCID'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "BADGE_ACTIVE_DATE" OPTIONS (
    column_name 'BADGE_ACTIVE_DATE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "BADGE_ACTIVE_SW" OPTIONS (
    column_name 'BADGE_ACTIVE_SW'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CLASS_TYPE" OPTIONS (
    column_name 'CLASS_TYPE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_ADDRESS1" OPTIONS (
    column_name 'CONTACT_ADDRESS1'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_ADDRESS2" OPTIONS (
    column_name 'CONTACT_ADDRESS2'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_ADDRESS3" OPTIONS (
    column_name 'CONTACT_ADDRESS3'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_ADDRESS4" OPTIONS (
    column_name 'CONTACT_ADDRESS4'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_BLD_NO" OPTIONS (
    column_name 'CONTACT_BLD_NO'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_CITY" OPTIONS (
    column_name 'CONTACT_CITY'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_COUNTRY" OPTIONS (
    column_name 'CONTACT_COUNTRY'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_COUNTY" OPTIONS (
    column_name 'CONTACT_COUNTY'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_LOCATION" OPTIONS (
    column_name 'CONTACT_LOCATION'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_MSIN" OPTIONS (
    column_name 'CONTACT_MSIN'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_PHON_CNTRY" OPTIONS (
    column_name 'CONTACT_PHON_CNTRY'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_PHONE" OPTIONS (
    column_name 'CONTACT_PHONE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_ROOM_NO" OPTIONS (
    column_name 'CONTACT_ROOM_NO'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_STATE" OPTIONS (
    column_name 'CONTACT_STATE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "CONTACT_ZIP" OPTIONS (
    column_name 'CONTACT_ZIP'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "DEPTID" OPTIONS (
    column_name 'DEPTID'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "EMPLOYED_BY_HCID" OPTIONS (
    column_name 'EMPLOYED_BY_HCID'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "ENTER_DATE" OPTIONS (
    column_name 'ENTER_DATE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "FIRST_NAME" OPTIONS (
    column_name 'FIRST_NAME'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "INTERNET_ADDRESS" OPTIONS (
    column_name 'INTERNET_ADDRESS'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "LAST_MOD_DATE" OPTIONS (
    column_name 'LAST_MOD_DATE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "LAST_MOD_ID" OPTIONS (
    column_name 'LAST_MOD_ID'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "LAST_NAME" OPTIONS (
    column_name 'LAST_NAME'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "MIDDLE_NAME" OPTIONS (
    column_name 'MIDDLE_NAME'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "NAME" OPTIONS (
    column_name 'NAME'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "NAME_SUFFIX" OPTIONS (
    column_name 'NAME_SUFFIX'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "PAY_NO" OPTIONS (
    column_name 'PAY_NO'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "PNL_ACT_DATE" OPTIONS (
    column_name 'PNL_ACT_DATE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "PNL_INACT_DATE" OPTIONS (
    column_name 'PNL_INACT_DATE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "PNL_MAINTAINED_SW" OPTIONS (
    column_name 'PNL_MAINTAINED_SW'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "POPFON_SW" OPTIONS (
    column_name 'POPFON_SW'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "PREF_FIRST_NAME" OPTIONS (
    column_name 'PREF_FIRST_NAME'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_ADDRESS1" OPTIONS (
    column_name 'WORK_ADDRESS1'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_ADDRESS2" OPTIONS (
    column_name 'WORK_ADDRESS2'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_ADDRESS3" OPTIONS (
    column_name 'WORK_ADDRESS3'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_ADDRESS4" OPTIONS (
    column_name 'WORK_ADDRESS4'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_BLD_NO" OPTIONS (
    column_name 'WORK_BLD_NO'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_CITY" OPTIONS (
    column_name 'WORK_CITY'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_COUNTRY" OPTIONS (
    column_name 'WORK_COUNTRY'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_COUNTY" OPTIONS (
    column_name 'WORK_COUNTY'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_LOCATION" OPTIONS (
    column_name 'WORK_LOCATION'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_MSIN" OPTIONS (
    column_name 'WORK_MSIN'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_PHON_CNTRY" OPTIONS (
    column_name 'WORK_PHON_CNTRY'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_PHONE" OPTIONS (
    column_name 'WORK_PHONE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_ROOM_NO" OPTIONS (
    column_name 'WORK_ROOM_NO'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_STATE" OPTIONS (
    column_name 'WORK_STATE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "WORK_ZIP" OPTIONS (
    column_name 'WORK_ZIP'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "PNL_NELS_POI_TYPE" OPTIONS (
    column_name 'PNL_NELS_POI_TYPE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "PERSON_TYPE" OPTIONS (
    column_name 'PERSON_TYPE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "PERSON_TYPE_DESC" OPTIONS (
    column_name 'PERSON_TYPE_DESC'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "PERSON_SUB_TYPE" OPTIONS (
    column_name 'PERSON_SUB_TYPE'
);
ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate ALTER COLUMN "PERSON_SUB_TYPE_DESC" OPTIONS (
    column_name 'PERSON_SUB_TYPE_DESC'
);


ALTER FOREIGN TABLE pnnldata.vw_pub_pnnl_associate OWNER TO d3l243;

