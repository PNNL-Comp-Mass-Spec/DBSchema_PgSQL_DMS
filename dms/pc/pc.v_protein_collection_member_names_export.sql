--
-- Name: v_protein_collection_member_names_export; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collection_member_names_export AS
 SELECT pcm.protein_collection_id,
    pc.collection_name AS protein_collection,
    pcm.protein_name,
    pcm.description,
    pcm.residue_count,
    pcm.monoisotopic_mass,
    pcm.protein_id,
    pcm.reference_id
   FROM (pc.t_protein_collection_members_cached pcm
     JOIN pc.t_protein_collections pc ON ((pcm.protein_collection_id = pc.protein_collection_id)));


ALTER TABLE pc.v_protein_collection_member_names_export OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_member_names_export; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_collection_member_names_export TO readaccess;

