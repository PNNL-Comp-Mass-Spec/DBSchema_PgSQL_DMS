--
-- Name: v_protein_storage_entry_import; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_storage_entry_import AS
 SELECT pn.name,
    pn.description,
    p.sequence,
    p.monoisotopic_mass,
    p.average_mass,
    p.length,
    p.molecular_formula,
    pn.annotation_type_id,
    p.protein_id,
    pn.reference_id,
    pcm.protein_collection_id,
    pc.primary_annotation_type_id,
    p.sha1_hash,
    pcm.member_id,
    pcm.sorting_index
   FROM (((pc.t_protein_collection_members pcm
     JOIN pc.t_proteins p ON ((pcm.protein_id = p.protein_id)))
     JOIN pc.t_protein_names pn ON (((pcm.protein_id = pn.protein_id) AND (pcm.original_reference_id = pn.reference_id))))
     JOIN pc.t_protein_collections pc ON ((pcm.protein_collection_id = pc.protein_collection_id)));


ALTER TABLE pc.v_protein_storage_entry_import OWNER TO d3l243;

