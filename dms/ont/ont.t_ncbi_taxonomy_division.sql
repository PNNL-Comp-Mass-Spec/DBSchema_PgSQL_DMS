--
-- Name: t_ncbi_taxonomy_division; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_ncbi_taxonomy_division (
    division_id smallint NOT NULL,
    division_code public.citext NOT NULL,
    division_name public.citext NOT NULL,
    comments public.citext
);


ALTER TABLE ont.t_ncbi_taxonomy_division OWNER TO d3l243;

--
-- Name: t_ncbi_taxonomy_division pk_t_ncbi_taxonomy_division; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ncbi_taxonomy_division
    ADD CONSTRAINT pk_t_ncbi_taxonomy_division PRIMARY KEY (division_id);

--
-- Name: TABLE t_ncbi_taxonomy_division; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_division TO readaccess;

