--
-- Name: t_archived_file_types; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_archived_file_types (
    archived_file_type_id integer NOT NULL,
    file_type_name public.citext NOT NULL,
    description public.citext
);


ALTER TABLE pc.t_archived_file_types OWNER TO d3l243;

--
-- Name: t_archived_file_types_archived_file_type_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_archived_file_types ALTER COLUMN archived_file_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_archived_file_types_archived_file_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_archived_file_types pk_t_archived_file_types; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_archived_file_types
    ADD CONSTRAINT pk_t_archived_file_types PRIMARY KEY (archived_file_type_id);

ALTER TABLE pc.t_archived_file_types CLUSTER ON pk_t_archived_file_types;

--
-- Name: TABLE t_archived_file_types; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_archived_file_types TO readaccess;
GRANT SELECT ON TABLE pc.t_archived_file_types TO writeaccess;

