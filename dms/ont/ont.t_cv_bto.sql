--
-- Name: t_cv_bto; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_cv_bto (
    entry_id integer NOT NULL,
    term_pk public.citext NOT NULL,
    term_name public.citext NOT NULL,
    identifier public.citext NOT NULL,
    is_leaf smallint NOT NULL,
    synonyms public.citext NOT NULL,
    parent_term_name public.citext NOT NULL,
    parent_term_id public.citext NOT NULL,
    grandparent_term_name public.citext,
    grandparent_term_id public.citext,
    children integer,
    usage_last_12_months integer DEFAULT 0 NOT NULL,
    usage_all_time integer DEFAULT 0 NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE ont.t_cv_bto OWNER TO d3l243;

--
-- Name: t_cv_bto pk_t_cv_bto; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_cv_bto
    ADD CONSTRAINT pk_t_cv_bto PRIMARY KEY (entry_id);

--
-- Name: ix_t_cv_bto_grandparent_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_bto_grandparent_term_name ON ont.t_cv_bto USING btree (grandparent_term_name);

--
-- Name: ix_t_cv_bto_identifier; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_bto_identifier ON ont.t_cv_bto USING btree (identifier) INCLUDE (term_name);

--
-- Name: ix_t_cv_bto_parent_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_bto_parent_term_name ON ont.t_cv_bto USING btree (parent_term_name);

--
-- Name: ix_t_cv_bto_synonyms; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_bto_synonyms ON ont.t_cv_bto USING btree (synonyms);

--
-- Name: ix_t_cv_bto_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_bto_term_name ON ont.t_cv_bto USING btree (term_name);

--
-- Name: ix_t_cv_bto_term_name_include_identifier; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_bto_term_name_include_identifier ON ont.t_cv_bto USING btree (term_name) INCLUDE (identifier);

