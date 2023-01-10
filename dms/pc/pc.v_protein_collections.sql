--
-- Name: v_protein_collections; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collections AS
 SELECT t_protein_collections.protein_collection_id,
    format('%s (%s Entries)'::text, t_protein_collections.collection_name, t_protein_collections.num_proteins) AS display,
    t_protein_collections.collection_name,
    t_protein_collections.primary_annotation_type_id,
    t_protein_collections.description,
    t_protein_collections.contents_encrypted,
    t_protein_collections.collection_type_id,
    t_protein_collections.collection_state_id,
    t_protein_collections.num_proteins,
    t_protein_collections.num_residues
   FROM pc.t_protein_collections;


ALTER TABLE pc.v_protein_collections OWNER TO d3l243;

--
-- Name: TABLE v_protein_collections; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_collections TO readaccess;
GRANT SELECT ON TABLE pc.v_protein_collections TO writeaccess;

