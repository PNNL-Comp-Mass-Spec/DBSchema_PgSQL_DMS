--
-- Name: v_protein_database_export; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_database_export AS
 SELECT p.protein_id,
    pn.name,
    "left"((pn.description)::text, 500) AS description,
    p.sequence,
    pc.protein_collection_id,
    pn.annotation_type_id,
    pc.primary_annotation_type_id,
    p.sha1_hash,
    pcm.sorting_index
   FROM (((pc.t_protein_collection_members pcm
     JOIN pc.t_proteins p ON ((pcm.protein_id = p.protein_id)))
     JOIN pc.t_protein_names pn ON (((pcm.protein_id = pn.protein_id) AND (pcm.original_reference_id = pn.reference_id))))
     JOIN pc.t_protein_collections pc ON ((pcm.protein_collection_id = pc.protein_collection_id)));


ALTER VIEW pc.v_protein_database_export OWNER TO d3l243;

--
-- Name: TABLE v_protein_database_export; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_database_export TO readaccess;
GRANT SELECT ON TABLE pc.v_protein_database_export TO writeaccess;

