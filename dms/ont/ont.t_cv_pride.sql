--
-- Name: t_cv_pride; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_cv_pride (
    entry_id integer NOT NULL,
    term_pk public.citext NOT NULL,
    term_name public.citext NOT NULL,
    identifier public.citext NOT NULL,
    is_leaf smallint NOT NULL,
    parent_term_name public.citext NOT NULL,
    parent_term_id public.citext NOT NULL,
    grandparent_term_name public.citext,
    grandparent_term_id public.citext,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE ont.t_cv_pride OWNER TO d3l243;

--
-- Name: t_cv_pride_entry_id_seq; Type: SEQUENCE; Schema: ont; Owner: d3l243
--

ALTER TABLE ont.t_cv_pride ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ont.t_cv_pride_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_cv_pride pk_t_cv_pride; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_cv_pride
    ADD CONSTRAINT pk_t_cv_pride PRIMARY KEY (entry_id);

ALTER TABLE ont.t_cv_pride CLUSTER ON pk_t_cv_pride;

--
-- Name: ix_t_cv_pride_grandparent_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_pride_grandparent_term_name ON ont.t_cv_pride USING btree (grandparent_term_name);

--
-- Name: ix_t_cv_pride_identifier; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_pride_identifier ON ont.t_cv_pride USING btree (identifier) INCLUDE (term_name);

--
-- Name: ix_t_cv_pride_parent_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_pride_parent_term_name ON ont.t_cv_pride USING btree (parent_term_name);

--
-- Name: ix_t_cv_pride_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_pride_term_name ON ont.t_cv_pride USING btree (term_name);

--
-- Name: TABLE t_cv_pride; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_cv_pride TO readaccess;
GRANT SELECT ON TABLE ont.t_cv_pride TO writeaccess;

