--
-- Name: v_protein_collections_list_report; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collections_list_report AS
 SELECT pc.protein_collection_id AS collection_id,
    pc.collection_name AS name,
    pc.description,
    pcs.state,
    pc.num_proteins AS protein_count,
    pc.num_residues AS residue_count,
    (((namingauth.name)::text || ' - '::text) || (antype.type_name)::text) AS annotation_type,
    pc.date_created AS created,
    pc.date_modified AS last_modified
   FROM ((pc.t_annotation_types antype
     JOIN pc.t_naming_authorities namingauth ON ((antype.authority_id = namingauth.authority_id)))
     JOIN (pc.t_protein_collections pc
     JOIN pc.t_protein_collection_states pcs ON ((pc.collection_state_id = pcs.collection_state_id))) ON ((antype.annotation_type_id = pc.primary_annotation_type_id)));


ALTER TABLE pc.v_protein_collections_list_report OWNER TO d3l243;

