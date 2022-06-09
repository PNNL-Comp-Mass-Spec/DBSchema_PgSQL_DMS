--
-- Name: t_cv_bto_cached_names; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_cv_bto_cached_names (
    entry_id integer NOT NULL,
    identifier public.citext NOT NULL,
    term_name public.citext NOT NULL
);


ALTER TABLE ont.t_cv_bto_cached_names OWNER TO d3l243;

--
-- Name: t_cv_bto_cached_names_entry_id_seq; Type: SEQUENCE; Schema: ont; Owner: d3l243
--

ALTER TABLE ont.t_cv_bto_cached_names ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ont.t_cv_bto_cached_names_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_cv_bto_cached_names pk_t_cv_bto_cached_names; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_cv_bto_cached_names
    ADD CONSTRAINT pk_t_cv_bto_cached_names PRIMARY KEY (identifier, term_name);

--
-- Name: ix_t_cv_bto_cached_names_term_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_cv_bto_cached_names_term_name ON ont.t_cv_bto_cached_names USING btree (term_name) INCLUDE (identifier);

