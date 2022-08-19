--
-- Name: v_protein_collections_detail_report; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_protein_collections_detail_report AS
 SELECT pc.protein_collection_id AS collection_id,
    pc.collection_name AS name,
    pc.description,
    pc.num_proteins AS protein_count,
    pc.num_residues AS residue_count,
    pc.date_created AS created,
    pc.date_modified AS last_modified,
    pct.type,
    pcs.state,
    pc.authentication_hash AS crc32_fingerprint,
    t_naming_authorities.name AS original_naming_authority
   FROM ((pc.t_annotation_types antype
     JOIN pc.t_naming_authorities ON ((antype.authority_id = t_naming_authorities.authority_id)))
     JOIN ((pc.t_protein_collections pc
     JOIN pc.t_protein_collection_states pcs ON ((pc.collection_state_id = pcs.collection_state_id)))
     JOIN pc.t_protein_collection_types pct ON ((pc.collection_type_id = pct.collection_type_id))) ON ((antype.annotation_type_id = pc.primary_annotation_type_id)));


ALTER TABLE pc.v_protein_collections_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_protein_collections_detail_report; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_protein_collections_detail_report TO readaccess;

