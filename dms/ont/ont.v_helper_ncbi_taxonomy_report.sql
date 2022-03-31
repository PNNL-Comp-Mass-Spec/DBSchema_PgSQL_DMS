--
-- Name: v_helper_ncbi_taxonomy_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_helper_ncbi_taxonomy_report AS
 SELECT nodes.tax_id,
    nodenames.name,
    nodes.rank,
    nodes.parent_tax_id,
    ont.gettaxidchildcount(nodes.tax_id) AS children,
    parentnodename.name AS parent_name,
    division.division_name AS division
   FROM (((((ont.t_ncbi_taxonomy_names nodenames
     JOIN ont.t_ncbi_taxonomy_nodes nodes ON ((nodenames.tax_id = nodes.tax_id)))
     JOIN ont.t_ncbi_taxonomy_division division ON ((nodes.division_id = division.division_id)))
     JOIN ont.t_ncbi_taxonomy_nodes parentnode ON ((nodes.parent_tax_id = parentnode.tax_id)))
     JOIN ont.t_ncbi_taxonomy_names parentnodename ON (((parentnode.tax_id = parentnodename.tax_id) AND (parentnodename.name_class OPERATOR(public.=) 'scientific name'::public.citext))))
     LEFT JOIN ont.t_ncbi_taxonomy_cached synonymstats ON ((nodes.tax_id = synonymstats.tax_id)))
  WHERE ((nodenames.name_class OPERATOR(public.=) 'scientific name'::public.citext) AND (NOT (nodes.rank OPERATOR(public.=) ANY (ARRAY['class'::public.citext, 'infraclass'::public.citext, 'infraorder'::public.citext, 'kingdom'::public.citext, 'order'::public.citext, 'parvorder'::public.citext, 'phylum'::public.citext, 'subclass'::public.citext, 'subkingdom'::public.citext, 'suborder'::public.citext, 'subphylum'::public.citext, 'subtribe'::public.citext, 'superclass'::public.citext, 'superfamily'::public.citext, 'superkingdom'::public.citext, 'superorder'::public.citext, 'superphylum'::public.citext, 'tribe'::public.citext]))));


ALTER TABLE ont.v_helper_ncbi_taxonomy_report OWNER TO d3l243;

