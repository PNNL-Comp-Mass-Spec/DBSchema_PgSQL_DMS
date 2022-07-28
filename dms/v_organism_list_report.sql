--
-- Name: v_organism_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_organism_list_report AS
 SELECT o.organism_id AS id,
    o.organism AS name,
    o.genus,
    o.species,
    o.strain,
    o.description,
    count(pc.collection_name) AS protein_collections,
    o.organism_db_name AS default_protein_collection,
    o.short_name,
    ncbi.name AS ncbi_taxonomy,
    o.ncbi_taxonomy_id,
    ncbi.synonyms AS ncbi_synonyms,
    o.storage_location AS storage_path,
    o.domain,
    o.kingdom,
    o.phylum,
    o.class,
    o."order",
    o.family,
    fastalookupq.legacy_fasta_files AS legacy_fastas,
    o.created,
    o.active
   FROM (((public.t_organisms o
     LEFT JOIN ( SELECT t_protein_collections.collection_name,
            orgxref.organism_id,
            pcs.state AS state_name
           FROM ((pc.t_protein_collections
             JOIN pc.t_collection_organism_xref orgxref ON ((t_protein_collections.protein_collection_id = orgxref.protein_collection_id)))
             JOIN pc.t_protein_collection_states pcs ON ((t_protein_collections.collection_state_id = pcs.collection_state_id)))) pc ON (((o.organism_id = pc.organism_id) AND (pc.state_name OPERATOR(public.<>) 'Retired'::public.citext))))
     LEFT JOIN ont.v_ncbi_taxonomy_cached ncbi ON ((o.ncbi_taxonomy_id = ncbi.tax_id)))
     LEFT JOIN ( SELECT odf.organism_id,
            count(*) AS legacy_fasta_files
           FROM public.t_organism_db_file odf
          WHERE ((odf.active > 0) AND (odf.valid > 0))
          GROUP BY odf.organism_id) fastalookupq ON ((o.organism_id = fastalookupq.organism_id)))
  GROUP BY o.organism_id, o.organism, o.genus, o.species, o.strain, o.description, o.organism_db_name, o.short_name, o.storage_location, o.domain, o.kingdom, o.phylum, o.class, o."order", o.family, o.created, o.active, o.ncbi_taxonomy_id, ncbi.name, ncbi.synonyms, fastalookupq.legacy_fasta_files;


ALTER TABLE public.v_organism_list_report OWNER TO d3l243;

--
-- Name: TABLE v_organism_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_organism_list_report TO readaccess;

