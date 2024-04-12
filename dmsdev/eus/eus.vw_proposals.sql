--
-- Name: vw_proposals; Type: FOREIGN TABLE; Schema: eus; Owner: d3l243
--

CREATE FOREIGN TABLE eus.vw_proposals (
    project_id character varying(64),
    title character varying(2048),
    proposal_type character varying(255),
    proposal_type_display character varying(255),
    actual_start_date date,
    actual_end_date date,
    project_uuid uuid
)
SERVER nexus_fdw
OPTIONS (
    schema_name 'proteomics_views',
    table_name 'vw_proposals'
);
ALTER FOREIGN TABLE eus.vw_proposals ALTER COLUMN project_id OPTIONS (
    column_name 'project_id'
);
ALTER FOREIGN TABLE eus.vw_proposals ALTER COLUMN title OPTIONS (
    column_name 'title'
);
ALTER FOREIGN TABLE eus.vw_proposals ALTER COLUMN proposal_type OPTIONS (
    column_name 'proposal_type'
);
ALTER FOREIGN TABLE eus.vw_proposals ALTER COLUMN proposal_type_display OPTIONS (
    column_name 'proposal_type_display'
);
ALTER FOREIGN TABLE eus.vw_proposals ALTER COLUMN actual_start_date OPTIONS (
    column_name 'actual_start_date'
);
ALTER FOREIGN TABLE eus.vw_proposals ALTER COLUMN actual_end_date OPTIONS (
    column_name 'actual_end_date'
);
ALTER FOREIGN TABLE eus.vw_proposals ALTER COLUMN project_uuid OPTIONS (
    column_name 'project_uuid'
);


ALTER FOREIGN TABLE eus.vw_proposals OWNER TO d3l243;

--
-- Name: TABLE vw_proposals; Type: ACL; Schema: eus; Owner: d3l243
--

GRANT SELECT ON TABLE eus.vw_proposals TO writeaccess;

