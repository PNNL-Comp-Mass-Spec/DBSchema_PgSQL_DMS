--
-- Name: t_protein_collection_types; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_protein_collection_types (
    collection_type_id smallint NOT NULL,
    type public.citext,
    display public.citext,
    description public.citext
);


ALTER TABLE pc.t_protein_collection_types OWNER TO d3l243;

--
-- Name: t_protein_collection_types_collection_type_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_protein_collection_types ALTER COLUMN collection_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_protein_collection_types_collection_type_id_seq
    START WITH 3
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_protein_collection_types pk_t_protein_collection_types; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collection_types
    ADD CONSTRAINT pk_t_protein_collection_types PRIMARY KEY (collection_type_id);

--
-- Name: TABLE t_protein_collection_types; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_protein_collection_types TO readaccess;
GRANT SELECT ON TABLE pc.t_protein_collection_types TO writeaccess;

