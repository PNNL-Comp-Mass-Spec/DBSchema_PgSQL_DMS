--
-- Name: t_organisms; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_organisms (
    organism_id integer NOT NULL,
    organism public.citext NOT NULL,
    organism_db_path public.citext GENERATED ALWAYS AS (
CASE
    WHEN (COALESCE(storage_location, ''::public.citext) OPERATOR(public.=) ''::public.citext) THEN NULL::text
    ELSE public.combine_paths((storage_location)::text, 'FASTA\'::text)
END) STORED,
    organism_db_name public.citext,
    created timestamp without time zone,
    description public.citext,
    short_name public.citext,
    storage_location public.citext,
    storage_url public.citext,
    domain public.citext,
    kingdom public.citext,
    phylum public.citext,
    class public.citext,
    "order" public.citext,
    family public.citext,
    genus public.citext,
    species public.citext,
    strain public.citext,
    dna_translation_table_id integer,
    mito_dna_translation_table_id integer,
    active smallint,
    newt_id_list public.citext,
    ncbi_taxonomy_id integer,
    auto_define_taxonomy smallint NOT NULL
);


ALTER TABLE public.t_organisms OWNER TO d3l243;

--
-- Name: TABLE t_organisms; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_organisms TO readaccess;

