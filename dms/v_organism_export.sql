--
-- Name: v_organism_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_organism_export AS
 SELECT DISTINCT o.organism_id,
    o.organism AS name,
    o.description,
    o.short_name,
    ncbi.name AS ncbi_taxonomy,
    o.ncbi_taxonomy_id,
    ncbi.synonyms AS ncbi_synonyms,
    o.domain,
    o.kingdom,
    o.phylum,
    o.class,
    o."order",
    o.family,
    o.genus,
    o.species,
    o.strain,
    o.dna_translation_table_id,
    o.mito_dna_translation_table_id,
    o.ncbi_taxonomy_id AS newt_id,
    newt.term_name AS newt_name,
    o.newt_id_list,
    o.created,
    o.active,
    o.organism_db_path AS organismdbpath
   FROM ((public.t_organisms o
     LEFT JOIN ( SELECT t_cv_newt.term_name,
            t_cv_newt.identifier
           FROM ont.t_cv_newt) newt ON ((o.ncbi_taxonomy_id = newt.identifier)))
     LEFT JOIN ( SELECT t_ncbi_taxonomy_cached.tax_id,
            t_ncbi_taxonomy_cached.name,
            t_ncbi_taxonomy_cached.synonyms
           FROM ont.t_ncbi_taxonomy_cached) ncbi ON ((o.ncbi_taxonomy_id = ncbi.tax_id)));


ALTER TABLE public.v_organism_export OWNER TO d3l243;

--
-- Name: TABLE v_organism_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_organism_export TO readaccess;
GRANT SELECT ON TABLE public.v_organism_export TO writeaccess;

