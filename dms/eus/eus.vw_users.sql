--
-- Name: vw_users; Type: FOREIGN TABLE; Schema: eus; Owner: d3l243
--

CREATE FOREIGN TABLE eus.vw_users (
    id integer,
    first_name character varying(64),
    last_name character varying(64),
    network_id text,
    emsl_employee boolean,
    email_address text,
    created_date timestamp(6) with time zone,
    last_change_date timestamp(6) with time zone
)
SERVER nexus_fdw
OPTIONS (
    schema_name 'proteomics_views',
    table_name 'vw_users'
);
ALTER FOREIGN TABLE ONLY eus.vw_users ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE ONLY eus.vw_users ALTER COLUMN first_name OPTIONS (
    column_name 'first_name'
);
ALTER FOREIGN TABLE ONLY eus.vw_users ALTER COLUMN last_name OPTIONS (
    column_name 'last_name'
);
ALTER FOREIGN TABLE ONLY eus.vw_users ALTER COLUMN network_id OPTIONS (
    column_name 'network_id'
);
ALTER FOREIGN TABLE ONLY eus.vw_users ALTER COLUMN emsl_employee OPTIONS (
    column_name 'emsl_employee'
);
ALTER FOREIGN TABLE ONLY eus.vw_users ALTER COLUMN email_address OPTIONS (
    column_name 'email_address'
);
ALTER FOREIGN TABLE ONLY eus.vw_users ALTER COLUMN created_date OPTIONS (
    column_name 'created_date'
);
ALTER FOREIGN TABLE ONLY eus.vw_users ALTER COLUMN last_change_date OPTIONS (
    column_name 'last_change_date'
);


ALTER FOREIGN TABLE eus.vw_users OWNER TO d3l243;

--
-- Name: TABLE vw_users; Type: ACL; Schema: eus; Owner: d3l243
--

GRANT SELECT ON TABLE eus.vw_users TO writeaccess;

