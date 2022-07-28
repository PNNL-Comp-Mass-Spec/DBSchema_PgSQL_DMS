--
-- Name: v_archived_output_file_stats_export; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_archived_output_file_stats_export AS
 SELECT aof.archived_file_id,
    aof.file_size_bytes,
    count(pc.protein_collection_id) AS protein_collection_count,
    sum(pc.num_proteins) AS protein_count,
    sum(pc.num_residues) AS residue_count,
    pc.get_file_name_from_path((aof.archived_file_path)::text) AS archived_file_name
   FROM ((pc.t_archived_output_files aof
     JOIN pc.t_archived_output_file_collections_xref aofc ON ((aof.archived_file_id = aofc.archived_file_id)))
     JOIN pc.t_protein_collections pc ON ((aofc.protein_collection_id = pc.protein_collection_id)))
  GROUP BY aof.archived_file_id, aof.file_size_bytes, (pc.get_file_name_from_path((aof.archived_file_path)::text));


ALTER TABLE pc.v_archived_output_file_stats_export OWNER TO d3l243;

