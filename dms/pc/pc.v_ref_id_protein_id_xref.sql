--
-- Name: v_ref_id_protein_id_xref; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_ref_id_protein_id_xref AS
 SELECT pcm.original_reference_id AS ref_id,
    pn.name,
    pn.description,
    orginfo.organism_name AS organism,
    pcm.protein_id
   FROM ((pc.v_organism_picker orginfo
     JOIN pc.t_collection_organism_xref orgxref ON ((orginfo.id = orgxref.organism_id)))
     JOIN (pc.t_protein_collection_members pcm
     JOIN pc.t_protein_names pn ON ((pcm.original_reference_id = pn.reference_id))) ON ((orgxref.protein_collection_id = pcm.protein_collection_id)));


ALTER TABLE pc.v_ref_id_protein_id_xref OWNER TO d3l243;

--
-- Name: TABLE v_ref_id_protein_id_xref; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_ref_id_protein_id_xref TO readaccess;

