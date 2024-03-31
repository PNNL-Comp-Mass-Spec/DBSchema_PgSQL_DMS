--
-- Name: v_missing_archive_entries; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_missing_archive_entries AS
 SELECT protein_collection_id,
    collection_name,
    authentication_hash,
    date_modified,
    collection_type_id,
    num_proteins
   FROM pc.t_protein_collections
  WHERE (NOT (authentication_hash OPERATOR(public.=) ANY ( SELECT t_archived_output_files.authentication_hash
           FROM pc.t_archived_output_files)));


ALTER VIEW pc.v_missing_archive_entries OWNER TO d3l243;

--
-- Name: TABLE v_missing_archive_entries; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_missing_archive_entries TO readaccess;
GRANT SELECT ON TABLE pc.v_missing_archive_entries TO writeaccess;

