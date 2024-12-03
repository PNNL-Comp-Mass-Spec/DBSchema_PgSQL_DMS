--
-- Name: vw_instruments; Type: FOREIGN TABLE; Schema: eus; Owner: d3l243
--

CREATE FOREIGN TABLE eus.vw_instruments (
    instrument_id integer,
    active_sw boolean,
    primary_instrument boolean,
    instrument_name character varying(255),
    eus_display_name character varying(255),
    available_hours character varying
)
SERVER nexus_fdw
OPTIONS (
    schema_name 'proteomics_views',
    table_name 'vw_instruments'
);
ALTER FOREIGN TABLE ONLY eus.vw_instruments ALTER COLUMN instrument_id OPTIONS (
    column_name 'instrument_id'
);
ALTER FOREIGN TABLE ONLY eus.vw_instruments ALTER COLUMN active_sw OPTIONS (
    column_name 'active_sw'
);
ALTER FOREIGN TABLE ONLY eus.vw_instruments ALTER COLUMN primary_instrument OPTIONS (
    column_name 'primary_instrument'
);
ALTER FOREIGN TABLE ONLY eus.vw_instruments ALTER COLUMN instrument_name OPTIONS (
    column_name 'instrument_name'
);
ALTER FOREIGN TABLE ONLY eus.vw_instruments ALTER COLUMN eus_display_name OPTIONS (
    column_name 'eus_display_name'
);
ALTER FOREIGN TABLE ONLY eus.vw_instruments ALTER COLUMN available_hours OPTIONS (
    column_name 'available_hours'
);


ALTER FOREIGN TABLE eus.vw_instruments OWNER TO d3l243;

--
-- Name: TABLE vw_instruments; Type: ACL; Schema: eus; Owner: d3l243
--

GRANT SELECT ON TABLE eus.vw_instruments TO writeaccess;

