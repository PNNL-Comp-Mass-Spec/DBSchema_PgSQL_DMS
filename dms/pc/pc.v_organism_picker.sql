--
-- Name: v_organism_picker; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_organism_picker AS
 SELECT org.organism_id AS id,
    org.organism AS short_name,
    (((org.organism)::text || (COALESCE((((' - '::public.citext)::text || (org.description)::text))::public.citext, ''::public.citext))::text))::public.citext AS display_name,
    (public.replace(org.organism_db_path, '\Fasta'::public.citext, ''::public.citext))::public.citext AS storage_location,
    (rtrim((
        CASE
            WHEN ((org.genus IS NOT NULL) AND (org.genus OPERATOR(public.<>) 'na'::public.citext)) THEN ((((((((((((COALESCE(org.genus, ''::public.citext))::text || (' '::public.citext)::text))::public.citext)::text || (COALESCE(org.species, ''::public.citext))::text))::public.citext)::text || (' '::public.citext)::text))::public.citext)::text || (COALESCE(org.strain, ''::public.citext))::text))::public.citext
            ELSE org.organism
        END)::text))::public.citext AS organism_name,
    (rtrim((
        CASE
            WHEN ((org.genus IS NOT NULL) AND (org.genus OPERATOR(public.<>) 'na'::public.citext) AND ((org.species IS NOT NULL) AND (org.species OPERATOR(public.<>) 'na'::public.citext))) THEN (((((COALESCE(("substring"((org.genus)::text, 1, 1) || '.'::text), ''::text) || ' '::text) || (COALESCE(org.species, ''::public.citext))::text) || ' '::text) || (COALESCE(org.strain, ''::public.citext))::text))::public.citext
            ELSE org.organism
        END)::text))::public.citext AS organism_name_abbrev_genus,
    org.short_name AS og_short_name,
    ((('organisms/'::public.citext)::text || lower((((
        CASE
            WHEN ((org.domain IS NULL) OR (org.domain OPERATOR(public.=) 'na'::public.citext)) THEN 'Uncategorized'::public.citext
            ELSE org.domain
        END)::text || (
        CASE
            WHEN ((org.kingdom IS NOT NULL) AND (org.kingdom OPERATOR(public.<>) 'na'::public.citext)) THEN ((('/'::public.citext)::text || (org.kingdom)::text))::public.citext
            ELSE ''::public.citext
        END)::text) || (
        CASE
            WHEN ((org.phylum IS NOT NULL) AND (org.phylum OPERATOR(public.<>) 'na'::public.citext)) THEN ((('/'::public.citext)::text || (org.phylum)::text))::public.citext
            ELSE ''::public.citext
        END)::text))))::public.citext AS search_terms,
    COALESCE(orgcounts.collection_count, (0)::bigint) AS collection_count
   FROM (public.t_organisms org
     LEFT JOIN pc.v_collection_counts_by_organism_id orgcounts ON ((org.organism_id = orgcounts.organism_id)));


ALTER VIEW pc.v_organism_picker OWNER TO d3l243;

--
-- Name: TABLE v_organism_picker; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_organism_picker TO readaccess;
GRANT SELECT ON TABLE pc.v_organism_picker TO writeaccess;

