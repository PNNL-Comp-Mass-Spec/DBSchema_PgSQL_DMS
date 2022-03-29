--
-- Name: t_cv_envo; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_cv_envo (
    entry_id integer NOT NULL,
    term_pk public.citext NOT NULL,
    term_name public.citext NOT NULL,
    identifier public.citext NOT NULL,
    is_leaf smallint NOT NULL,
    synonyms public.citext NOT NULL,
    parent_term_name public.citext NOT NULL,
    parent_term_id public.citext NOT NULL,
    grand_parent_term_name public.citext,
    grand_parent_term_id public.citext,
    children integer,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE ont.t_cv_envo OWNER TO d3l243;

--
-- Name: t_cv_envo_entry_id_seq; Type: SEQUENCE; Schema: ont; Owner: d3l243
--

ALTER TABLE ont.t_cv_envo ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ont.t_cv_envo_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_cv_envo pk_t_cv_envo; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_cv_envo
    ADD CONSTRAINT pk_t_cv_envo PRIMARY KEY (entry_id);

--
-- Name: ix_t_cv_envo_cached_names_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_envo_cached_names_term_name ON ont.t_cv_envo USING btree (term_name) INCLUDE (identifier);

--
-- Name: ix_t_cv_envo_grand_parent_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_envo_grand_parent_term_name ON ont.t_cv_envo USING btree (grand_parent_term_name);

--
-- Name: ix_t_cv_envo_identifier; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_envo_identifier ON ont.t_cv_envo USING btree (identifier) INCLUDE (term_name);

--
-- Name: ix_t_cv_envo_parent_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_envo_parent_term_name ON ont.t_cv_envo USING btree (parent_term_name);

--
-- Name: ix_t_cv_envo_synonyms; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_envo_synonyms ON ont.t_cv_envo USING btree (synonyms);

--
-- Name: ix_t_cv_envo_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_envo_term_name ON ont.t_cv_envo USING btree (term_name);

