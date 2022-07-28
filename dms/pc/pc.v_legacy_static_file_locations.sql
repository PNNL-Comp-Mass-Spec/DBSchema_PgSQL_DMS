--
-- Name: v_legacy_static_file_locations; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_legacy_static_file_locations AS
 SELECT orgdbinfo.org_db_file_id AS id,
    orgdbinfo.file_name,
    public.combine_paths((org.organism_db_path)::text, (orgdbinfo.file_name)::text) AS full_path,
    org.organism_id,
    org.organism AS organism_name,
    public.replace(orgdbinfo.file_name, '.fasta'::public.citext, ''::public.citext) AS default_collection_name,
    COALESCE(lfur.authentication_hash, ''::public.citext) AS authentication_hash
   FROM ((public.t_organism_db_file orgdbinfo
     JOIN public.t_organisms org ON ((orgdbinfo.organism_id = org.organism_id)))
     LEFT JOIN ( SELECT t_legacy_file_upload_requests.legacy_file_name AS file_name,
            t_legacy_file_upload_requests.authentication_hash
           FROM pc.t_legacy_file_upload_requests) lfur ON ((orgdbinfo.file_name OPERATOR(public.=) lfur.file_name)));


ALTER TABLE pc.v_legacy_static_file_locations OWNER TO d3l243;

