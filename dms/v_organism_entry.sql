--
-- Name: v_organism_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_organism_entry AS
 SELECT org.organism_id AS id,
    org.organism,
    org.organism_db_name AS default_protein_collection,
    org.description,
    org.short_name,
    org.storage_location,
    org.ncbi_taxonomy_id,
    t_yes_no.description AS auto_define_taxonomy,
    org.domain,
    org.kingdom,
    org.phylum,
    org.class,
    org."order",
    org.family,
    org.genus,
    org.species,
    org.strain,
    org.newt_id_list,
    org.active
   FROM (public.t_organisms org
     JOIN public.t_yes_no ON ((org.auto_define_taxonomy = t_yes_no.flag)));


ALTER VIEW public.v_organism_entry OWNER TO d3l243;

--
-- Name: TABLE v_organism_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_organism_entry TO readaccess;
GRANT SELECT ON TABLE public.v_organism_entry TO writeaccess;

