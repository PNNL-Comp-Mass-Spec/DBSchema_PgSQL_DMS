--
-- Name: t_ncbi_taxonomy_gen_code; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_ncbi_taxonomy_gen_code (
    genetic_code_id smallint NOT NULL,
    abbreviation public.citext,
    genetic_code_name public.citext NOT NULL,
    code_table public.citext NOT NULL,
    starts public.citext NOT NULL
);


ALTER TABLE ont.t_ncbi_taxonomy_gen_code OWNER TO d3l243;

--
-- Name: t_ncbi_taxonomy_gen_code pk_t_ncbi_taxonomy_gen_code; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ncbi_taxonomy_gen_code
    ADD CONSTRAINT pk_t_ncbi_taxonomy_gen_code PRIMARY KEY (genetic_code_id);

--
-- Name: TABLE t_ncbi_taxonomy_gen_code; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_gen_code TO readaccess;
GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_gen_code TO writeaccess;

