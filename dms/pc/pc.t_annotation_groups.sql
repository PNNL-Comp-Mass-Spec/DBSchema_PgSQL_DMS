--
-- Name: t_annotation_groups; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_annotation_groups (
    annotation_group_id integer NOT NULL,
    protein_collection_id integer NOT NULL,
    annotation_group smallint NOT NULL,
    annotation_type_id integer NOT NULL
);


ALTER TABLE pc.t_annotation_groups OWNER TO d3l243;

--
-- Name: t_annotation_groups_annotation_group_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_annotation_groups ALTER COLUMN annotation_group_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_annotation_groups_annotation_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_annotation_groups pk_t_annotation_groups; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_annotation_groups
    ADD CONSTRAINT pk_t_annotation_groups PRIMARY KEY (annotation_group_id);

--
-- Name: t_annotation_groups fk_t_annotation_groups_t_annotation_types; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_annotation_groups
    ADD CONSTRAINT fk_t_annotation_groups_t_annotation_types FOREIGN KEY (annotation_type_id) REFERENCES pc.t_annotation_types(annotation_type_id);

--
-- Name: t_annotation_groups fk_t_annotation_groups_t_protein_collections; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_annotation_groups
    ADD CONSTRAINT fk_t_annotation_groups_t_protein_collections FOREIGN KEY (protein_collection_id) REFERENCES pc.t_protein_collections(protein_collection_id);

