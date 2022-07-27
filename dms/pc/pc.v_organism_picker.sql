--
-- Name: v_organism_picker; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_organism_picker AS
 SELECT org.organism_id AS id,
    org.organism AS short_name,
    ((org.organism)::text || COALESCE((' - '::text || (org.description)::text), ''::text)) AS display_name,
    public.replace(org.organism_db_path, '\Fasta'::public.citext, ''::public.citext) AS storage_location,
    rtrim(
        CASE
            WHEN ((org.genus IS NOT NULL) AND (org.genus OPERATOR(public.<>) 'na'::public.citext)) THEN (((((COALESCE(org.genus, ''::public.citext))::text || ' '::text) || (COALESCE(org.species, ''::public.citext))::text) || ' '::text) || (COALESCE(org.strain, ''::public.citext))::text)
            ELSE (org.organism)::text
        END) AS organism_name,
    rtrim(
        CASE
            WHEN ((org.genus IS NOT NULL) AND (org.genus OPERATOR(public.<>) 'na'::public.citext) AND ((org.species IS NOT NULL) AND (org.species OPERATOR(public.<>) 'na'::public.citext))) THEN ((((COALESCE(("substring"((org.genus)::text, 1, 1) || '.'::text), ''::text) || ' '::text) || (COALESCE(org.species, ''::public.citext))::text) || ' '::text) || (COALESCE(org.strain, ''::public.citext))::text)
            ELSE (org.organism)::text
        END) AS organism_name_abbrev_genus,
    org.short_name AS og_short_name,
    ('organisms/'::text || lower((((
        CASE
            WHEN ((org.domain IS NULL) OR (org.domain OPERATOR(public.=) 'na'::public.citext)) THEN 'Uncategorized'::public.citext
            ELSE org.domain
        END)::text ||
        CASE
            WHEN ((org.kingdom IS NOT NULL) AND (org.kingdom OPERATOR(public.<>) 'na'::public.citext)) THEN ('/'::text || (org.kingdom)::text)
            ELSE ''::text
        END) ||
        CASE
            WHEN ((org.phylum IS NOT NULL) AND (org.phylum OPERATOR(public.<>) 'na'::public.citext)) THEN ('/'::text || (org.phylum)::text)
            ELSE ''::text
        END))) AS search_terms,
    COALESCE(orgcounts.collection_count, (0)::bigint) AS collection_count
   FROM (public.t_organisms org
     LEFT JOIN pc.v_collection_counts_by_organism_id orgcounts ON ((org.organism_id = orgcounts.organism_id)));


ALTER TABLE pc.v_organism_picker OWNER TO d3l243;

