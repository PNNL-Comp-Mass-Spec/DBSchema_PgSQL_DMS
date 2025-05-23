--
-- Name: t_archived_output_file_collections_xref; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_archived_output_file_collections_xref (
    entry_id integer NOT NULL,
    archived_file_id integer NOT NULL,
    protein_collection_id integer NOT NULL
);


ALTER TABLE pc.t_archived_output_file_collections_xref OWNER TO d3l243;

--
-- Name: t_archived_output_file_collections_xref_entry_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_archived_output_file_collections_xref ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_archived_output_file_collections_xref_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_archived_output_file_collections_xref pk_t_archived_output_file_collections_xref; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_archived_output_file_collections_xref
    ADD CONSTRAINT pk_t_archived_output_file_collections_xref PRIMARY KEY (entry_id);

ALTER TABLE pc.t_archived_output_file_collections_xref CLUSTER ON pk_t_archived_output_file_collections_xref;

--
-- Name: TABLE t_archived_output_file_collections_xref; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_archived_output_file_collections_xref TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_archived_output_file_collections_xref TO writeaccess;
GRANT INSERT,DELETE,UPDATE ON TABLE pc.t_archived_output_file_collections_xref TO pceditor;

