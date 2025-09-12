--
-- Name: v_protein_collections; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collections AS
 SELECT pc.protein_collection_id,
    pc.collection_name,
    pc.description,
    pc.source,
    pc.collection_type_id,
    pc.collection_state_id,
    pcs.state,
    pc.primary_annotation_type_id,
    ((((((namingauth.name)::text || (' - '::public.citext)::text))::public.citext)::text || (antype.type_name)::text))::public.citext AS annotation_type,
    pc.num_proteins,
    pc.num_residues,
    pc.includes_contaminants,
    pc.date_created,
    pc.date_modified,
    (format('%s (%s Entries)'::text, pc.collection_name, pc.num_proteins))::public.citext AS display,
    pc.authentication_hash,
    pc.contents_encrypted,
    pc.uploaded_by
   FROM ((pc.t_annotation_types antype
     JOIN pc.t_naming_authorities namingauth ON ((antype.authority_id = namingauth.authority_id)))
     JOIN (pc.t_protein_collections pc
     JOIN pc.t_protein_collection_states pcs ON ((pc.collection_state_id = pcs.collection_state_id))) ON ((antype.annotation_type_id = pc.primary_annotation_type_id)));


ALTER VIEW pc.v_protein_collections OWNER TO d3l243;

--
-- Name: TABLE v_protein_collections; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_collections TO readaccess;
GRANT SELECT ON TABLE pc.v_protein_collections TO writeaccess;

