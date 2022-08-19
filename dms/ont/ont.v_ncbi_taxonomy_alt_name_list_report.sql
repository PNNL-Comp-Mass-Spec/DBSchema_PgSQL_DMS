--
-- Name: v_ncbi_taxonomy_alt_name_list_report; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_ncbi_taxonomy_alt_name_list_report AS
 SELECT primaryname.tax_id,
    primaryname.name AS scientific_name,
    namelist.name_class AS synonym_type,
    namelist.name AS synonym,
    nodes.rank,
    nodes.parent_tax_id,
    parentnodename.name AS parent_name,
    division.division_name AS division
   FROM (((((ont.t_ncbi_taxonomy_names namelist
     JOIN ont.t_ncbi_taxonomy_names primaryname ON (((namelist.tax_id = primaryname.tax_id) AND (primaryname.name_class OPERATOR(public.=) 'scientific name'::public.citext))))
     JOIN ont.t_ncbi_taxonomy_name_class nameclass ON ((namelist.name_class OPERATOR(public.=) nameclass.name_class)))
     JOIN ont.t_ncbi_taxonomy_nodes nodes ON ((primaryname.tax_id = nodes.tax_id)))
     JOIN ont.t_ncbi_taxonomy_names parentnodename ON (((nodes.parent_tax_id = parentnodename.tax_id) AND (parentnodename.name_class OPERATOR(public.=) 'scientific name'::public.citext))))
     JOIN ont.t_ncbi_taxonomy_division division ON ((nodes.division_id = division.division_id)))
  WHERE ((nameclass.sort_weight >= 2) AND (nameclass.sort_weight <= 19));


ALTER TABLE ont.v_ncbi_taxonomy_alt_name_list_report OWNER TO d3l243;

--
-- Name: TABLE v_ncbi_taxonomy_alt_name_list_report; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_ncbi_taxonomy_alt_name_list_report TO readaccess;
GRANT SELECT ON TABLE ont.v_ncbi_taxonomy_alt_name_list_report TO writeaccess;

