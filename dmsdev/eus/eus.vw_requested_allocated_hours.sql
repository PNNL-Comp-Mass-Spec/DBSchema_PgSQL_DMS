--
-- Name: vw_requested_allocated_hours; Type: FOREIGN TABLE; Schema: eus; Owner: d3l243
--

CREATE FOREIGN TABLE eus.vw_requested_allocated_hours (
    instrument_id integer,
    eus_display_name text,
    proposal_id character varying(64),
    requested_hours integer,
    allocated_hours integer,
    fy text
)
SERVER nexus_fdw
OPTIONS (
    schema_name 'proteomics_views',
    table_name 'vw_requested_allocated_hours'
);
ALTER FOREIGN TABLE eus.vw_requested_allocated_hours ALTER COLUMN instrument_id OPTIONS (
    column_name 'instrument_id'
);
ALTER FOREIGN TABLE eus.vw_requested_allocated_hours ALTER COLUMN eus_display_name OPTIONS (
    column_name 'eus_display_name'
);
ALTER FOREIGN TABLE eus.vw_requested_allocated_hours ALTER COLUMN proposal_id OPTIONS (
    column_name 'proposal_id'
);
ALTER FOREIGN TABLE eus.vw_requested_allocated_hours ALTER COLUMN requested_hours OPTIONS (
    column_name 'requested_hours'
);
ALTER FOREIGN TABLE eus.vw_requested_allocated_hours ALTER COLUMN allocated_hours OPTIONS (
    column_name 'allocated_hours'
);
ALTER FOREIGN TABLE eus.vw_requested_allocated_hours ALTER COLUMN fy OPTIONS (
    column_name 'fy'
);


ALTER FOREIGN TABLE eus.vw_requested_allocated_hours OWNER TO d3l243;

--
-- Name: TABLE vw_requested_allocated_hours; Type: ACL; Schema: eus; Owner: d3l243
--

GRANT SELECT ON TABLE eus.vw_requested_allocated_hours TO writeaccess;

