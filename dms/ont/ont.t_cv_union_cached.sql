--
-- Name: t_cv_union_cached; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_cv_union_cached (
    entry_id integer NOT NULL,
    source public.citext,
    term_pk public.citext,
    term_name public.citext,
    identifier public.citext,
    is_leaf smallint,
    parent_term_name public.citext,
    parent_term_id public.citext,
    grandparent_term_name public.citext,
    grandparent_term_id public.citext
);


ALTER TABLE ont.t_cv_union_cached OWNER TO d3l243;

--
-- Name: t_cv_union_cached_entry_id_seq; Type: SEQUENCE; Schema: ont; Owner: d3l243
--

ALTER TABLE ont.t_cv_union_cached ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ont.t_cv_union_cached_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_cv_union_cached pk_t_cv_union_cached; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_cv_union_cached
    ADD CONSTRAINT pk_t_cv_union_cached PRIMARY KEY (entry_id);

--
-- Name: ix_t_cv_union_cached_grandparent_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_union_cached_grandparent_term_name ON ont.t_cv_union_cached USING btree (grandparent_term_name);

--
-- Name: ix_t_cv_union_cached_identifier_include_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_union_cached_identifier_include_term_name ON ont.t_cv_union_cached USING btree (identifier) INCLUDE (term_name);

--
-- Name: ix_t_cv_union_cached_parent_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_union_cached_parent_term_name ON ont.t_cv_union_cached USING btree (parent_term_name);

--
-- Name: ix_t_cv_union_cached_source; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_union_cached_source ON ont.t_cv_union_cached USING btree (source);

--
-- Name: ix_t_cv_union_cached_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_union_cached_term_name ON ont.t_cv_union_cached USING btree (term_name);

--
-- Name: ix_t_cv_union_cached_term_name_include_identifier; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_union_cached_term_name_include_identifier ON ont.t_cv_union_cached USING btree (term_name) INCLUDE (identifier);

--
-- Name: ix_t_cv_union_cached_term_pk; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_union_cached_term_pk ON ont.t_cv_union_cached USING btree (term_pk);

--
-- Name: TABLE t_cv_union_cached; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_cv_union_cached TO readaccess;
GRANT SELECT ON TABLE ont.t_cv_union_cached TO writeaccess;

