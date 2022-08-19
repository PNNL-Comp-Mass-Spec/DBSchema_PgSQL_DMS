--
-- Name: t_ontology; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_ontology (
    ontology_id integer NOT NULL,
    short_name public.citext NOT NULL,
    fully_loaded smallint DEFAULT 0 NOT NULL,
    uses_imports smallint NOT NULL,
    full_name public.citext,
    query_url public.citext,
    source_url public.citext,
    definition public.citext,
    load_date timestamp without time zone,
    version public.citext
);


ALTER TABLE ont.t_ontology OWNER TO d3l243;

--
-- Name: t_ontology pk_ontology; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ontology
    ADD CONSTRAINT pk_ontology PRIMARY KEY (ontology_id);

--
-- Name: ix_t_ontology_short_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_ontology_short_name ON ont.t_ontology USING btree (short_name);

--
-- Name: TABLE t_ontology; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_ontology TO readaccess;
GRANT SELECT ON TABLE ont.t_ontology TO writeaccess;

