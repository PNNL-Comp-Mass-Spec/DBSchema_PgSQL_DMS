--
-- Name: v_protein_collection_member_ids; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collection_member_ids AS
 SELECT pcm.protein_id,
    pcm.protein_collection_id,
    pcm.original_reference_id
   FROM (pc.t_proteins p
     JOIN pc.t_protein_collection_members pcm ON ((p.protein_id = pcm.protein_id)));


ALTER VIEW pc.v_protein_collection_member_ids OWNER TO d3l243;

--
-- Name: TABLE v_protein_collection_member_ids; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_collection_member_ids TO readaccess;
GRANT SELECT ON TABLE pc.v_protein_collection_member_ids TO writeaccess;

