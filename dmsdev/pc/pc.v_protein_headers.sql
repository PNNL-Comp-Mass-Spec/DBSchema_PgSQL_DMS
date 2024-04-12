--
-- Name: v_protein_headers; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_headers AS
 SELECT h.protein_id,
    pn.name AS protein_name,
    pc.protein_collection_id,
    pc.collection_name AS protein_collection_name,
    h.sequence_head
   FROM (((pc.t_protein_headers h
     JOIN pc.t_protein_names pn ON ((h.protein_id = pn.protein_id)))
     JOIN pc.t_protein_collection_members pcm ON ((pn.reference_id = pcm.original_reference_id)))
     JOIN pc.t_protein_collections pc ON ((pcm.protein_collection_id = pc.protein_collection_id)));


ALTER VIEW pc.v_protein_headers OWNER TO d3l243;

--
-- Name: TABLE v_protein_headers; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_headers TO readaccess;
GRANT SELECT ON TABLE pc.v_protein_headers TO writeaccess;

