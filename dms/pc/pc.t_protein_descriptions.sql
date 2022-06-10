--
-- Name: t_protein_descriptions; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_protein_descriptions (
    description_id integer NOT NULL,
    description public.citext,
    fingerprint public.citext,
    date_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    reference_id integer NOT NULL
);


ALTER TABLE pc.t_protein_descriptions OWNER TO d3l243;

--
-- Name: t_protein_descriptions_description_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_protein_descriptions ALTER COLUMN description_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_protein_descriptions_description_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_protein_descriptions pk_t_protein_descriptions; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_descriptions
    ADD CONSTRAINT pk_t_protein_descriptions PRIMARY KEY (description_id);

--
-- Name: ix_descriptions; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_descriptions ON pc.t_protein_descriptions USING btree (description);

--
-- Name: ix_tpd_ref_id; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_tpd_ref_id ON pc.t_protein_descriptions USING btree (reference_id);

--
-- Name: t_protein_descriptions fk_t_protein_descriptions_t_protein_names; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_descriptions
    ADD CONSTRAINT fk_t_protein_descriptions_t_protein_names FOREIGN KEY (reference_id) REFERENCES pc.t_protein_names(reference_id);

