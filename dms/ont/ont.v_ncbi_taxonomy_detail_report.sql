--
-- Name: v_ncbi_taxonomy_detail_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_ncbi_taxonomy_detail_report AS
 SELECT nodes.tax_id,
    nodenames.name,
    nodenames.unique_name,
    synonymstats.synonyms,
    synonymstats.synonym_list,
    nodes.comments,
    nodes.parent_tax_id,
    parentnodename.name AS parent_name,
    ont.get_taxid_child_count(nodes.tax_id) AS children,
    nodes.embl_code,
    division.division_name AS division,
    ont.get_taxid_taxonomy_list(nodes.tax_id, 1) AS taxonomy_list,
    nodes.genetic_code_id,
    gencode.genetic_code_name,
    nodes.mito_genetic_code_id,
    gencodemit.genetic_code_name AS mito_gen_code_name,
    nodes.gen_bank_hidden,
    nodes.rank
   FROM (((((((ont.t_ncbi_taxonomy_names nodenames
     JOIN ont.t_ncbi_taxonomy_nodes nodes ON ((nodenames.tax_id = nodes.tax_id)))
     JOIN ont.t_ncbi_taxonomy_division division ON ((nodes.division_id = division.division_id)))
     JOIN ont.t_ncbi_taxonomy_gen_code gencode ON ((nodes.genetic_code_id = gencode.genetic_code_id)))
     JOIN ont.t_ncbi_taxonomy_nodes parentnode ON ((nodes.parent_tax_id = parentnode.tax_id)))
     JOIN ont.t_ncbi_taxonomy_names parentnodename ON (((parentnode.tax_id = parentnodename.tax_id) AND (parentnodename.name_class OPERATOR(public.=) 'scientific name'::public.citext))))
     JOIN ont.t_ncbi_taxonomy_gen_code gencodemit ON ((nodes.mito_genetic_code_id = gencodemit.genetic_code_id)))
     LEFT JOIN ont.t_ncbi_taxonomy_cached synonymstats ON ((nodes.tax_id = synonymstats.tax_id)))
  WHERE (nodenames.name_class OPERATOR(public.=) 'scientific name'::public.citext);


ALTER TABLE ont.v_ncbi_taxonomy_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_ncbi_taxonomy_detail_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_ncbi_taxonomy_detail_report TO readaccess;
GRANT SELECT ON TABLE ont.v_ncbi_taxonomy_detail_report TO writeaccess;

