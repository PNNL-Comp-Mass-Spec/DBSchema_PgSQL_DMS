--
-- Name: t_archived_file_creation_options; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_archived_file_creation_options (
    creation_option_id integer NOT NULL,
    keyword_id integer NOT NULL,
    value_id integer NOT NULL,
    archived_file_id integer NOT NULL
);


ALTER TABLE pc.t_archived_file_creation_options OWNER TO d3l243;

--
-- Name: t_archived_file_creation_options_creation_option_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_archived_file_creation_options ALTER COLUMN creation_option_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_archived_file_creation_options_creation_option_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_archived_file_creation_options pk_t_archived_file_creation_options; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_archived_file_creation_options
    ADD CONSTRAINT pk_t_archived_file_creation_options PRIMARY KEY (creation_option_id);

--
-- Name: TABLE t_archived_file_creation_options; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_archived_file_creation_options TO readaccess;
GRANT SELECT ON TABLE pc.t_archived_file_creation_options TO writeaccess;

