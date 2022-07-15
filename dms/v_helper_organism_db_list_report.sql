--
-- Name: v_helper_organism_db_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_organism_db_list_report AS
 SELECT f.org_db_file_id AS id,
    f.file_name AS name,
    o.organism,
    f.description,
    f.num_proteins,
    f.num_residues,
    (f.created)::date AS created,
    round(((f.file_size_kb / (1024.0)::double precision))::numeric, 2) AS size_mb
   FROM (public.t_organism_db_file f
     JOIN public.t_organisms o ON ((f.organism_id = o.organism_id)))
  WHERE ((f.active > 0) AND (f.valid > 0));


ALTER TABLE public.v_helper_organism_db_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_organism_db_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_organism_db_list_report TO readaccess;

