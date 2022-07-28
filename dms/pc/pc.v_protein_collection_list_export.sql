--
-- Name: v_protein_collection_list_export; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collection_list_export AS
 SELECT pc.protein_collection_id,
    pc.collection_name AS name,
    pc.description,
    pcs.state AS collection_state,
    pct.type AS collection_type,
    pc.num_proteins AS protein_count,
    pc.num_residues AS residue_count,
    nameauth.name AS annotation_naming_authority,
    antype.type_name AS annotation_type,
    orgxref.organism_id,
    pc.date_created AS created,
    pc.date_modified AS last_modified,
    pc.authentication_hash
   FROM (((((pc.t_protein_collections pc
     JOIN pc.t_protein_collection_types pct ON ((pc.collection_type_id = pct.collection_type_id)))
     JOIN pc.t_protein_collection_states pcs ON ((pc.collection_state_id = pcs.collection_state_id)))
     JOIN pc.t_annotation_types antype ON ((pc.primary_annotation_type_id = antype.annotation_type_id)))
     JOIN pc.t_naming_authorities nameauth ON ((antype.authority_id = nameauth.authority_id)))
     LEFT JOIN pc.t_collection_organism_xref orgxref ON ((pc.protein_collection_id = orgxref.protein_collection_id)));


ALTER TABLE pc.v_protein_collection_list_export OWNER TO d3l243;

