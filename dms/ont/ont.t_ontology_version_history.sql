--
-- Name: t_ontology_version_history; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_ontology_version_history (
    entry_id integer NOT NULL,
    ontology public.citext NOT NULL,
    version public.citext,
    release_date timestamp without time zone,
    entered_in_dms timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    download_url public.citext,
    comments public.citext
);


ALTER TABLE ont.t_ontology_version_history OWNER TO d3l243;

--
-- Name: t_ontology_version_history_entry_id_seq; Type: SEQUENCE; Schema: ont; Owner: d3l243
--

ALTER TABLE ont.t_ontology_version_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ont.t_ontology_version_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_ontology_version_history pk_t_ontology_version_history; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ontology_version_history
    ADD CONSTRAINT pk_t_ontology_version_history PRIMARY KEY (entry_id);

ALTER TABLE ont.t_ontology_version_history CLUSTER ON pk_t_ontology_version_history;

--
-- Name: TABLE t_ontology_version_history; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_ontology_version_history TO readaccess;
GRANT SELECT ON TABLE ont.t_ontology_version_history TO writeaccess;

