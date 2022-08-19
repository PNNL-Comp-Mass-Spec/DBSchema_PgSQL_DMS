--
-- Name: t_term_synonym; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_term_synonym (
    synonym_pk public.citext NOT NULL,
    term_pk public.citext NOT NULL,
    synonym_type_pk public.citext,
    synonym_value public.citext
);


ALTER TABLE ont.t_term_synonym OWNER TO d3l243;

--
-- Name: t_term_synonym pk_term_synonym; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_term_synonym
    ADD CONSTRAINT pk_term_synonym PRIMARY KEY (synonym_pk);

--
-- Name: t_term_synonym fk_term_synonym_term; Type: FK CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_term_synonym
    ADD CONSTRAINT fk_term_synonym_term FOREIGN KEY (term_pk) REFERENCES ont.t_term(term_pk);

--
-- Name: TABLE t_term_synonym; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_term_synonym TO readaccess;

