--
-- Name: v_legacy_fasta_file_paths; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_legacy_fasta_file_paths AS
 SELECT t_organism_db_file.file_name,
    ((t_organisms.organism_db_path)::text || (t_organism_db_file.file_name)::text) AS file_path,
    t_organisms.organism_id
   FROM (public.t_organism_db_file
     JOIN public.t_organisms ON ((t_organism_db_file.organism_id = t_organisms.organism_id)));


ALTER TABLE public.v_legacy_fasta_file_paths OWNER TO d3l243;

--
-- Name: TABLE v_legacy_fasta_file_paths; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_legacy_fasta_file_paths TO readaccess;
GRANT SELECT ON TABLE public.v_legacy_fasta_file_paths TO writeaccess;

