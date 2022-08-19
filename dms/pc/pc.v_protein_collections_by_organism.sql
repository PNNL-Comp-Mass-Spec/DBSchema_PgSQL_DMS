--
-- Name: v_protein_collections_by_organism; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collections_by_organism AS
 SELECT DISTINCT pc.protein_collection_id,
    ((((pc.collection_name)::text || ' ('::text) || (pc.num_proteins)::text) || ' Entries)'::text) AS display,
    pc.description,
    pc.source,
    pc.collection_state_id,
    pcs.state AS state_name,
    pc.collection_type_id,
    pctypes.type,
    pc.num_proteins,
    pc.num_residues,
    pc.authentication_hash,
    pc.collection_name,
    orgxref.organism_id,
    pc.primary_annotation_type_id AS authority_id,
    org.organism AS organism_name,
    pc.contents_encrypted,
    pc.includes_contaminants,
    aof.file_size_bytes
   FROM (((((pc.t_protein_collections pc
     JOIN pc.t_collection_organism_xref orgxref ON ((pc.protein_collection_id = orgxref.protein_collection_id)))
     JOIN public.t_organisms org ON ((orgxref.organism_id = org.organism_id)))
     JOIN pc.t_protein_collection_types pctypes ON ((pc.collection_type_id = pctypes.collection_type_id)))
     JOIN pc.t_protein_collection_states pcs ON ((pc.collection_state_id = pcs.collection_state_id)))
     LEFT JOIN pc.t_archived_output_files aof ON ((pc.authentication_hash OPERATOR(public.=) aof.authentication_hash)));


ALTER TABLE pc.v_protein_collections_by_organism OWNER TO d3l243;

--
-- Name: TABLE v_protein_collections_by_organism; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_collections_by_organism TO readaccess;
GRANT SELECT ON TABLE pc.v_protein_collections_by_organism TO writeaccess;

