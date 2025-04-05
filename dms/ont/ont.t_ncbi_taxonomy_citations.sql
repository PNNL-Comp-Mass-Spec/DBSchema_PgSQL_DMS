--
-- Name: t_ncbi_taxonomy_citations; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_ncbi_taxonomy_citations (
    citation_id integer NOT NULL,
    citation_key public.citext NOT NULL,
    pub_med_id integer NOT NULL,
    med_line_id integer NOT NULL,
    url public.citext,
    article_text public.citext,
    tax_id_list public.citext
);


ALTER TABLE ont.t_ncbi_taxonomy_citations OWNER TO d3l243;

--
-- Name: t_ncbi_taxonomy_citations pk_t_ncbi_taxonomy_citations; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ncbi_taxonomy_citations
    ADD CONSTRAINT pk_t_ncbi_taxonomy_citations PRIMARY KEY (citation_id);

ALTER TABLE ont.t_ncbi_taxonomy_citations CLUSTER ON pk_t_ncbi_taxonomy_citations;

--
-- Name: TABLE t_ncbi_taxonomy_citations; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_citations TO readaccess;
GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_citations TO writeaccess;

