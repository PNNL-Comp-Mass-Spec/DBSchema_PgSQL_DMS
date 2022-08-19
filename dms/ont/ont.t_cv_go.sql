--
-- Name: t_cv_go; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_cv_go (
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


ALTER TABLE ont.t_cv_go OWNER TO d3l243;

--
-- Name: t_cv_go_entry_id_seq; Type: SEQUENCE; Schema: ont; Owner: d3l243
--

ALTER TABLE ont.t_cv_go ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ont.t_cv_go_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_cv_go pk_t_cv_go; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_cv_go
    ADD CONSTRAINT pk_t_cv_go PRIMARY KEY (entry_id);

--
-- Name: ix_t_cv_go_grandparent_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_go_grandparent_term_name ON ont.t_cv_go USING btree (grandparent_term_name);

--
-- Name: ix_t_cv_go_parent_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_go_parent_term_name ON ont.t_cv_go USING btree (parent_term_name);

--
-- Name: ix_t_cv_go_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_go_term_name ON ont.t_cv_go USING btree (term_name);

--
-- Name: TABLE t_cv_go; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_cv_go TO readaccess;
GRANT SELECT ON TABLE ont.t_cv_go TO writeaccess;

