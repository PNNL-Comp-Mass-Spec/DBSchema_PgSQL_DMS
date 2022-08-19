--
-- Name: vw_proposal_participants; Type: FOREIGN TABLE; Schema: eus; Owner: d3l243
--

CREATE FOREIGN TABLE eus.vw_proposal_participants (
    project_id character varying(64),
    user_id integer,
    hanford_id text,
    last_name character varying(64),
    first_name character varying(64),
    name_fm text
)
SERVER nexus_fdw
OPTIONS (
    schema_name 'proteomics_views',
    table_name 'vw_proposal_participants'
);
ALTER FOREIGN TABLE eus.vw_proposal_participants ALTER COLUMN project_id OPTIONS (
    column_name 'project_id'
);
ALTER FOREIGN TABLE eus.vw_proposal_participants ALTER COLUMN user_id OPTIONS (
    column_name 'user_id'
);
ALTER FOREIGN TABLE eus.vw_proposal_participants ALTER COLUMN hanford_id OPTIONS (
    column_name 'hanford_id'
);
ALTER FOREIGN TABLE eus.vw_proposal_participants ALTER COLUMN last_name OPTIONS (
    column_name 'last_name'
);
ALTER FOREIGN TABLE eus.vw_proposal_participants ALTER COLUMN first_name OPTIONS (
    column_name 'first_name'
);
ALTER FOREIGN TABLE eus.vw_proposal_participants ALTER COLUMN name_fm OPTIONS (
    column_name 'name_fm'
);


ALTER FOREIGN TABLE eus.vw_proposal_participants OWNER TO d3l243;

--
-- Name: TABLE vw_proposal_participants; Type: ACL; Schema: eus; Owner: d3l243
--

GRANT SELECT ON TABLE eus.vw_proposal_participants TO writeaccess;

