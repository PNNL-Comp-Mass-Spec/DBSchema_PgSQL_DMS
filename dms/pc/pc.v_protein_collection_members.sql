--
-- Name: v_protein_collection_members; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collection_members AS
 SELECT pn.reference_id,
    pn.name,
    pn.description,
    pn.annotation_type_id,
    pcm.protein_id,
    pcm.protein_collection_id,
    pcm.original_reference_id
   FROM ((pc.t_protein_names pn
     JOIN pc.t_proteins p ON ((pn.protein_id = p.protein_id)))
     JOIN pc.t_protein_collection_members pcm ON (((p.protein_id = pcm.protein_id) AND (pn.reference_id = pcm.original_reference_id))));


ALTER TABLE pc.v_protein_collection_members OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_members; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_collection_members TO readaccess;
GRANT SELECT ON TABLE pc.v_protein_collection_members TO writeaccess;

