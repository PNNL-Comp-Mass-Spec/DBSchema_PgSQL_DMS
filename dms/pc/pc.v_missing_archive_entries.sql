--
-- Name: v_missing_archive_entries; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_missing_archive_entries AS
 SELECT t_protein_collections.protein_collection_id,
    t_protein_collections.collection_name,
    t_protein_collections.authentication_hash,
    t_protein_collections.date_modified,
    t_protein_collections.collection_type_id,
    t_protein_collections.num_proteins
   FROM pc.t_protein_collections
  WHERE (NOT (t_protein_collections.authentication_hash OPERATOR(public.=) ANY ( SELECT t_archived_output_files.authentication_hash
           FROM pc.t_archived_output_files)));


ALTER VIEW pc.v_missing_archive_entries OWNER TO d3l243;

--
-- Name: TABLE v_missing_archive_entries; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_missing_archive_entries TO readaccess;
GRANT SELECT ON TABLE pc.v_missing_archive_entries TO writeaccess;

