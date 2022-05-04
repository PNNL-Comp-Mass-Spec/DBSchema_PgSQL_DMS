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
    dna_translation_table_id integer DEFAULT 0,
    mito_dna_translation_table_id integer DEFAULT 0,
    active smallint DEFAULT 1,
    newt_id_list public.citext,
    ncbi_taxonomy_id integer,
    auto_define_taxonomy smallint DEFAULT 1 NOT NULL
);


ALTER TABLE public.t_organisms OWNER TO d3l243;

--
-- Name: t_organisms ix_t_organisms_unique_organism; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_organisms
    ADD CONSTRAINT ix_t_organisms_unique_organism UNIQUE (organism);

--
-- Name: t_organisms pk_t_organisms; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_organisms
    ADD CONSTRAINT pk_t_organisms PRIMARY KEY (organism_id);

--
-- Name: ix_t_organisms_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_organisms_created ON public.t_organisms USING btree (created);

--
-- Name: TABLE t_organisms; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_organisms TO readaccess;

