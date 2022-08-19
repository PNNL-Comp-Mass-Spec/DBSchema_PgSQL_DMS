--
-- Name: v_archived_output_files; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_archived_output_files AS
 SELECT aof.archived_file_id,
    xref.protein_collection_id,
    aof.authentication_hash,
    aof.archived_file_path,
    fs.archived_file_state,
    ft.file_type_name AS archived_file_type,
    aof.archived_file_creation_date,
    aof.file_modification_date,
    aof.creation_options,
    round((((aof.file_size_bytes)::numeric / 1024.0) / 1024.0), 3) AS file_size_mb
   FROM (((pc.t_archived_output_files aof
     JOIN pc.t_archived_output_file_collections_xref xref ON ((aof.archived_file_id = xref.archived_file_id)))
     JOIN pc.t_archived_file_states fs ON ((aof.archived_file_state_id = fs.archived_file_state_id)))
     JOIN pc.t_archived_file_types ft ON ((aof.archived_file_type_id = ft.archived_file_type_id)));


ALTER TABLE pc.v_archived_output_files OWNER TO d3l243;

--
-- Name: TABLE v_archived_output_files; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_archived_output_files TO readaccess;
GRANT SELECT ON TABLE pc.v_archived_output_files TO writeaccess;

