--
-- Name: v_organism_db_file_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_organism_db_file_export AS
 SELECT odf.org_db_file_id AS id,
    odf.file_name AS filename,
    o.organism,
    odf.description,
    odf.active,
    odf.num_proteins AS numproteins,
    odf.num_residues AS numresidues,
    odf.organism_id,
    odf.xmin AS orgfile_rowversion,
    odf.file_size_kb
   FROM (public.t_organism_db_file odf
     JOIN public.t_organisms o ON ((odf.organism_id = o.organism_id)))
  WHERE (odf.valid > 0);


ALTER VIEW public.v_organism_db_file_export OWNER TO d3l243;

--
-- Name: TABLE v_organism_db_file_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_organism_db_file_export TO readaccess;
GRANT SELECT ON TABLE public.v_organism_db_file_export TO writeaccess;

