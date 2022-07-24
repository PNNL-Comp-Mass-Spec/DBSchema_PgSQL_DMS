--
-- Name: v_archived_output_files; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_archived_output_files AS
 SELECT aof.archived_file_id,
    xref.protein_collection_id,
    aof.authentication_hash,
    aof.archived_file_path,
    filestate.archived_file_state,
    filetype.file_type_name AS archived_file_type,
    aof.archived_file_creation_date,
    aof.file_modification_date,
    aof.creation_options,
    (((aof.filesize)::numeric / 1024.0) / 1024.0) AS file_size_mb
   FROM (((pc.t_archived_output_files aof
     JOIN pc.t_archived_output_file_collections_xref xref ON ((aof.archived_file_id = xref.archived_file_id)))
     JOIN pc.t_archived_file_states filestate ON ((aof.archived_file_state_id = filestate.archived_file_state_id)))
     JOIN pc.t_archived_file_types filetype ON ((aof.archived_file_type_id = filetype.archived_file_type_id)));


ALTER TABLE pc.v_archived_output_files OWNER TO d3l243;

