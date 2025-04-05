--
-- Name: t_ncbi_taxonomy_cached; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_ncbi_taxonomy_cached (
    tax_id integer NOT NULL,
    name public.citext NOT NULL,
    rank public.citext NOT NULL,
    parent_tax_id integer NOT NULL,
    synonyms integer DEFAULT 0 NOT NULL,
    synonym_list public.citext
);


ALTER TABLE ont.t_ncbi_taxonomy_cached OWNER TO d3l243;

--
-- Name: t_ncbi_taxonomy_cached pk_t_ncbi_taxonomy_cached; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ncbi_taxonomy_cached
    ADD CONSTRAINT pk_t_ncbi_taxonomy_cached PRIMARY KEY (tax_id);

ALTER TABLE ont.t_ncbi_taxonomy_cached CLUSTER ON pk_t_ncbi_taxonomy_cached;

--
-- Name: ix_t_ncbi_taxonomy_cached_tax_id_include_name_and_synomyms; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_ncbi_taxonomy_cached_tax_id_include_name_and_synomyms ON ont.t_ncbi_taxonomy_cached USING btree (tax_id) INCLUDE (name, synonyms);

--
-- Name: TABLE t_ncbi_taxonomy_cached; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_cached TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE ont.t_ncbi_taxonomy_cached TO writeaccess;

