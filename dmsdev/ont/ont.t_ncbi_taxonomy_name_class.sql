--
-- Name: t_ncbi_taxonomy_name_class; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_ncbi_taxonomy_name_class (
    name_class public.citext NOT NULL,
    sort_weight smallint NOT NULL
);


ALTER TABLE ont.t_ncbi_taxonomy_name_class OWNER TO d3l243;

--
-- Name: t_ncbi_taxonomy_name_class pk_t_ncbi_taxonomy_name_class; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ncbi_taxonomy_name_class
    ADD CONSTRAINT pk_t_ncbi_taxonomy_name_class PRIMARY KEY (name_class);

--
-- Name: ix_t_ncbi_taxonomy_name_class_sort_weight; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_ncbi_taxonomy_name_class_sort_weight ON ont.t_ncbi_taxonomy_name_class USING btree (sort_weight) INCLUDE (name_class);

--
-- Name: TABLE t_ncbi_taxonomy_name_class; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_name_class TO readaccess;
GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_name_class TO writeaccess;

