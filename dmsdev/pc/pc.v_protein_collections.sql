--
-- Name: v_protein_collections; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collections AS
 SELECT protein_collection_id,
    (format('%s (%s Entries)'::text, collection_name, num_proteins))::public.citext AS display,
    collection_name,
    primary_annotation_type_id,
    description,
    contents_encrypted,
    collection_type_id,
    collection_state_id,
    num_proteins,
    num_residues
   FROM pc.t_protein_collections;


ALTER VIEW pc.v_protein_collections OWNER TO d3l243;

--
-- Name: TABLE v_protein_collections; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_collections TO readaccess;
GRANT SELECT ON TABLE pc.v_protein_collections TO writeaccess;

