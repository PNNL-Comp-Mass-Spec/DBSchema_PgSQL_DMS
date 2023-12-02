--
-- Name: v_organism_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_organism_detail_report AS
 SELECT o.organism_id AS id,
    o.organism AS name,
    o.short_name,
    o.description,
    ncbi.name AS ncbi_taxonomy,
    o.ncbi_taxonomy_id,
    ncbi.synonyms AS ncbi_synonyms,
    ncbi.synonym_list AS ncbi_synonym_list,
    newt.term_name AS newt_name,
    ont.get_taxid_taxonomy_list(o.ncbi_taxonomy_id, 0) AS taxonomy_list,
    o.domain,
    o.kingdom,
    o.phylum AS phylum_or_division,
    o.class,
    o."order",
    o.family,
    o.genus,
    o.species,
    o.strain,
    o.newt_id_list,
    o.created,
    count(pc.collection_name) AS protein_collections,
    o.storage_location AS organism_storage_path,
    o.storage_url AS organism_storage_link,
    o.organism_db_name AS default_protein_collection,
    fastalookupq.legacy_fasta_files,
    o.active,
    t_yes_no.description AS auto_define_taxonomy
   FROM (((((public.t_organisms o
     JOIN public.t_yes_no ON ((o.auto_define_taxonomy = t_yes_no.flag)))
     LEFT JOIN ont.t_cv_newt newt ON ((o.ncbi_taxonomy_id = newt.identifier)))
     LEFT JOIN ( SELECT t_protein_collections.collection_name,
            orgxref.organism_id,
            pcs.state AS state_name
           FROM ((pc.t_protein_collections
             JOIN pc.t_collection_organism_xref orgxref ON ((t_protein_collections.protein_collection_id = orgxref.protein_collection_id)))
             JOIN pc.t_protein_collection_states pcs ON ((t_protein_collections.collection_state_id = pcs.collection_state_id)))) pc ON (((o.organism_id = pc.organism_id) AND (pc.state_name OPERATOR(public.<>) 'Retired'::public.citext))))
     LEFT JOIN ont.t_ncbi_taxonomy_cached ncbi ON ((o.ncbi_taxonomy_id = ncbi.tax_id)))
     LEFT JOIN ( SELECT odf.organism_id,
            count(odf.org_db_file_id) AS legacy_fasta_files
           FROM public.t_organism_db_file odf
          WHERE ((odf.active > 0) AND (odf.valid > 0))
          GROUP BY odf.organism_id) fastalookupq ON ((o.organism_id = fastalookupq.organism_id)))
  GROUP BY o.organism_id, o.organism, o.genus, o.species, o.strain, o.description, o.short_name, o.domain, o.kingdom, o.phylum, o.class, o."order", o.family, o.newt_id_list, newt.term_name, o.created, o.active, o.storage_location, o.storage_url, o.organism_db_name, fastalookupq.legacy_fasta_files, o.ncbi_taxonomy_id, ncbi.name, ncbi.synonyms, ncbi.synonym_list, t_yes_no.description;


ALTER VIEW public.v_organism_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_organism_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_organism_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_organism_detail_report TO writeaccess;

