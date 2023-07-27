--
-- Name: v_organism_db_file; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_organism_db_file AS
 SELECT orgdbfile.org_db_file_id AS id,
    orgdbfile.file_name,
    orgdbfile.organism_id,
    org.organism,
    orgdbfile.description,
    orgdbfile.num_proteins,
    orgdbfile.num_residues,
    orgdbfile.valid,
    orgdbfile.file_size_kb,
    orgdbfile.active,
    orgdbfile.xmin AS org_file_row_version,
    org.organism_db_path AS folder_server,
    public.replace(org.organism_db_path, mpath.server, mpath.client) AS folder_client
   FROM ((public.t_organism_db_file orgdbfile
     JOIN public.t_organisms org ON ((orgdbfile.organism_id = org.organism_id)))
     CROSS JOIN ( SELECT t_misc_paths.server,
            t_misc_paths.client
           FROM public.t_misc_paths
          WHERE (t_misc_paths.path_function OPERATOR(public.=) 'DMSOrganismFiles'::public.citext)) mpath);


ALTER TABLE public.v_organism_db_file OWNER TO d3l243;

--
-- Name: TABLE v_organism_db_file; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_organism_db_file TO readaccess;
GRANT SELECT ON TABLE public.v_organism_db_file TO writeaccess;

