--
-- Name: v_protein_collection_members_cached; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collection_members_cached AS
 SELECT pcm.protein_collection_id,
    pc.collection_name AS protein_collection,
    pcm.protein_name,
    pcm.description,
    pcm.reference_id,
    pcm.residue_count,
    pcm.monoisotopic_mass,
    pcm.protein_id,
    h.sequence_head
   FROM ((pc.t_protein_collection_members_cached pcm
     JOIN pc.t_protein_collections pc ON ((pcm.protein_collection_id = pc.protein_collection_id)))
     JOIN pc.t_protein_headers h ON ((h.protein_id = pcm.protein_id)));


ALTER VIEW pc.v_protein_collection_members_cached OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_members_cached; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_collection_members_cached TO readaccess;
GRANT SELECT ON TABLE pc.v_protein_collection_members_cached TO writeaccess;

