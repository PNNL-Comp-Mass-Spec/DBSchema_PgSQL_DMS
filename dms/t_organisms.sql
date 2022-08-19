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
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
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
    auto_define_taxonomy smallint DEFAULT 1 NOT NULL,
    CONSTRAINT ck_t_organisms_name_no_space_or_comma CHECK (((NOT (organism OPERATOR(public.~~) '% %'::public.citext)) AND (NOT (organism OPERATOR(public.~~) '%,%'::public.citext)))),
    CONSTRAINT ck_t_organisms_organism_name_white_space CHECK ((public.has_whitespace_chars((organism)::text, 0) = false)),
    CONSTRAINT ck_t_organisms_short_name_no_space_or_comma CHECK (((NOT (short_name OPERATOR(public.~~) '% %'::public.citext)) AND (NOT (short_name OPERATOR(public.~~) '%,%'::public.citext))))
);


ALTER TABLE public.t_organisms OWNER TO d3l243;

--
-- Name: t_organisms_organism_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_organisms ALTER COLUMN organism_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_organisms_organism_id_seq
    START WITH 40
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

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
-- Name: t_organisms trig_t_organisms_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_organisms_after_insert AFTER INSERT ON public.t_organisms REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_organisms_after_insert();

--
-- Name: t_organisms trig_t_organisms_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_organisms_after_update AFTER UPDATE ON public.t_organisms FOR EACH ROW WHEN (((old.organism OPERATOR(public.<>) new.organism) OR (old.short_name IS DISTINCT FROM new.short_name) OR (old.domain IS DISTINCT FROM new.domain) OR (old.kingdom IS DISTINCT FROM new.kingdom) OR (old.phylum IS DISTINCT FROM new.phylum) OR (old.class IS DISTINCT FROM new.class) OR (old."order" IS DISTINCT FROM new."order") OR (old.family IS DISTINCT FROM new.family) OR (old.genus IS DISTINCT FROM new.genus) OR (old.species IS DISTINCT FROM new.species) OR (old.strain IS DISTINCT FROM new.strain) OR (old.newt_id_list IS DISTINCT FROM new.newt_id_list) OR (old.ncbi_taxonomy_id IS DISTINCT FROM new.ncbi_taxonomy_id) OR (old.active IS DISTINCT FROM new.active))) EXECUTE FUNCTION public.trigfn_t_organisms_after_update();

--
-- Name: t_organisms fk_t_organisms_t_yes_no; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_organisms
    ADD CONSTRAINT fk_t_organisms_t_yes_no FOREIGN KEY (auto_define_taxonomy) REFERENCES public.t_yes_no(flag);

--
-- Name: TABLE t_organisms; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_organisms TO readaccess;
GRANT SELECT ON TABLE public.t_organisms TO writeaccess;

