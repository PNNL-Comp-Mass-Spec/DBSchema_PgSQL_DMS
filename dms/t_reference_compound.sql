--
-- Name: t_reference_compound; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_reference_compound (
    compound_id integer NOT NULL,
    compound_name public.citext NOT NULL,
    description public.citext,
    compound_type_id integer NOT NULL,
    gene_name public.citext,
    modifications public.citext,
    organism_id integer NOT NULL,
    pub_chem_cid integer,
    campaign_id integer NOT NULL,
    container_id integer DEFAULT 1 NOT NULL,
    wellplate_name public.citext,
    well_number public.citext,
    contact_username public.citext,
    supplier public.citext,
    product_id public.citext,
    purchase_date timestamp without time zone,
    purity public.citext,
    purchase_quantity public.citext,
    mass double precision,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    active smallint DEFAULT 1 NOT NULL,
    id_name public.citext GENERATED ALWAYS AS (((((compound_id)::public.citext)::text || ':'::text) || (compound_name)::text)) STORED,
    CONSTRAINT ck_t_reference_compound_name_whitespace CHECK ((public.has_whitespace_chars((compound_name)::text, true) = false))
);


ALTER TABLE public.t_reference_compound OWNER TO d3l243;

--
-- Name: t_reference_compound_compound_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_reference_compound ALTER COLUMN compound_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_reference_compound_compound_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_reference_compound pk_t_reference_compound; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reference_compound
    ADD CONSTRAINT pk_t_reference_compound PRIMARY KEY (compound_id);

ALTER TABLE public.t_reference_compound CLUSTER ON pk_t_reference_compound;

--
-- Name: ix_t_reference_compound_campaign_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_reference_compound_campaign_id ON public.t_reference_compound USING btree (campaign_id);

--
-- Name: ix_t_reference_compound_container_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_reference_compound_container_id ON public.t_reference_compound USING btree (container_id);

--
-- Name: ix_t_reference_compound_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_reference_compound_created ON public.t_reference_compound USING btree (created);

--
-- Name: ix_t_reference_compound_id_name_computed_column; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_reference_compound_id_name_computed_column ON public.t_reference_compound USING btree (id_name);

--
-- Name: ix_t_reference_compound_id_name_container; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_reference_compound_id_name_container ON public.t_reference_compound USING btree (compound_id, compound_name, container_id);

--
-- Name: ix_t_reference_compound_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_reference_compound_name ON public.t_reference_compound USING btree (compound_name);

--
-- Name: ix_t_reference_compound_name_container_id_compound_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_reference_compound_name_container_id_compound_id ON public.t_reference_compound USING btree (compound_name, container_id, compound_id);

--
-- Name: t_reference_compound trig_t_reference_compound_after_delete; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_reference_compound_after_delete AFTER DELETE ON public.t_reference_compound REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_reference_compound_after_delete();

--
-- Name: t_reference_compound trig_t_reference_compound_after_insert; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_reference_compound_after_insert AFTER INSERT ON public.t_reference_compound REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION public.trigfn_t_reference_compound_after_insert();

--
-- Name: t_reference_compound trig_t_reference_compound_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_reference_compound_after_update AFTER UPDATE ON public.t_reference_compound FOR EACH ROW WHEN (((old.compound_name OPERATOR(public.<>) new.compound_name) OR ((old.modifications)::text IS DISTINCT FROM (new.modifications)::text) OR ((old.gene_name)::text IS DISTINCT FROM (new.gene_name)::text))) EXECUTE FUNCTION public.trigfn_t_reference_compound_after_update();

--
-- Name: t_reference_compound fk_t_reference_compound_t_campaign; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reference_compound
    ADD CONSTRAINT fk_t_reference_compound_t_campaign FOREIGN KEY (campaign_id) REFERENCES public.t_campaign(campaign_id);

--
-- Name: t_reference_compound fk_t_reference_compound_t_material_containers; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reference_compound
    ADD CONSTRAINT fk_t_reference_compound_t_material_containers FOREIGN KEY (container_id) REFERENCES public.t_material_containers(container_id);

--
-- Name: t_reference_compound fk_t_reference_compound_t_organisms; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reference_compound
    ADD CONSTRAINT fk_t_reference_compound_t_organisms FOREIGN KEY (organism_id) REFERENCES public.t_organisms(organism_id);

--
-- Name: t_reference_compound fk_t_reference_compound_t_reference_compound_type_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reference_compound
    ADD CONSTRAINT fk_t_reference_compound_t_reference_compound_type_name FOREIGN KEY (compound_type_id) REFERENCES public.t_reference_compound_type_name(compound_type_id);

--
-- Name: t_reference_compound fk_t_reference_compound_t_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reference_compound
    ADD CONSTRAINT fk_t_reference_compound_t_users FOREIGN KEY (contact_username) REFERENCES public.t_users(username) ON UPDATE CASCADE;

--
-- Name: TABLE t_reference_compound; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_reference_compound TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_reference_compound TO writeaccess;

