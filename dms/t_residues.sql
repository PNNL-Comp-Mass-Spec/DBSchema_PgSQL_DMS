--
-- Name: t_residues; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_residues (
    residue_id integer NOT NULL,
    residue_symbol public.citext NOT NULL,
    description public.citext NOT NULL,
    abbreviation public.citext DEFAULT ''::public.citext NOT NULL,
    average_mass double precision NOT NULL,
    monoisotopic_mass double precision NOT NULL,
    num_c smallint NOT NULL,
    num_h smallint NOT NULL,
    num_n smallint NOT NULL,
    num_o smallint NOT NULL,
    num_s smallint NOT NULL,
    empirical_formula public.citext,
    amino_acid_name public.citext
);


ALTER TABLE public.t_residues OWNER TO d3l243;

--
-- Name: t_residues_residue_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_residues ALTER COLUMN residue_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_residues_residue_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_residues pk_t_residues; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_residues
    ADD CONSTRAINT pk_t_residues PRIMARY KEY (residue_id);

ALTER TABLE public.t_residues CLUSTER ON pk_t_residues;

--
-- Name: ix_t_residues_symbol; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_residues_symbol ON public.t_residues USING btree (residue_symbol);

--
-- Name: t_residues trig_t_residues_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_residues_after_insert AFTER INSERT ON public.t_residues REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_residues_after_insert();

--
-- Name: t_residues trig_t_residues_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_residues_after_update AFTER UPDATE ON public.t_residues FOR EACH ROW WHEN (((old.residue_symbol OPERATOR(public.<>) new.residue_symbol) OR (old.average_mass <> new.average_mass) OR (old.monoisotopic_mass <> new.monoisotopic_mass) OR (old.num_c <> new.num_c) OR (old.num_h <> new.num_h) OR (old.num_n <> new.num_n) OR (old.num_o <> new.num_o) OR (old.num_s <> new.num_s))) EXECUTE FUNCTION public.trigfn_t_residues_after_update();

--
-- Name: TABLE t_residues; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_residues TO readaccess;
GRANT SELECT ON TABLE public.t_residues TO writeaccess;

