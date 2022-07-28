--
-- Name: v_archived_output_file_protein_collections; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_archived_output_file_protein_collections AS
 SELECT aof.archived_file_id,
    aof.archived_file_path,
    t_archived_file_types.file_type_name,
    t_archived_file_states.archived_file_state,
    lookupq.protein_collection_count,
    aofc.protein_collection_id,
    pc.collection_name
   FROM (((((pc.t_archived_output_files aof
     JOIN ( SELECT aof_1.archived_file_id,
            count(*) AS protein_collection_count
           FROM (pc.t_archived_output_files aof_1
             JOIN pc.t_archived_output_file_collections_xref aofc_1 ON ((aof_1.archived_file_id = aofc_1.archived_file_id)))
          GROUP BY aof_1.archived_file_id) lookupq ON ((aof.archived_file_id = lookupq.archived_file_id)))
     JOIN pc.t_archived_output_file_collections_xref aofc ON ((aof.archived_file_id = aofc.archived_file_id)))
     JOIN pc.t_protein_collections pc ON ((aofc.protein_collection_id = pc.protein_collection_id)))
     JOIN pc.t_archived_file_types ON ((aof.archived_file_type_id = t_archived_file_types.archived_file_type_id)))
     JOIN pc.t_archived_file_states ON ((aof.archived_file_state_id = t_archived_file_states.archived_file_state_id)));


ALTER TABLE pc.v_archived_output_file_protein_collections OWNER TO d3l243;

