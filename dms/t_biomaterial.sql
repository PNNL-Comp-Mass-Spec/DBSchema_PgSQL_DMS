--
-- Name: t_biomaterial; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_biomaterial (
    biomaterial_id integer NOT NULL,
    biomaterial_name public.citext NOT NULL,
    source_name public.citext,
    contact_prn public.citext,
    pi_prn public.citext,
    biomaterial_type integer,
    reason public.citext,
    comment public.citext,
    campaign_id integer,
    container_id integer DEFAULT 1 NOT NULL,
    material_active public.citext DEFAULT 'Active'::public.citext NOT NULL,
    created timestamp without time zone,
    gene_name public.citext,
    gene_location public.citext,
    mod_count smallint,
    modifications public.citext,
    mass double precision,
    purchase_date timestamp without time zone,
    peptide_purity public.citext,
    purchase_quantity public.citext,
    cached_organism_list public.citext,
    mutation public.citext,
    plasmid public.citext,
    cell_line public.citext,
    CONSTRAINT ck_t_biomaterial_cell_culture_name_white_space CHECK ((public.has_whitespace_chars((biomaterial_name)::text, 1) = false))
);


ALTER TABLE public.t_biomaterial OWNER TO d3l243;

--
-- Name: t_biomaterial_biomaterial_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_biomaterial ALTER COLUMN biomaterial_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_biomaterial_biomaterial_id_seq
    START WITH 200
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_biomaterial pk_t_biomaterial; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_biomaterial
    ADD CONSTRAINT pk_t_biomaterial PRIMARY KEY (biomaterial_id);

--
-- Name: ix_t_biomaterial_biomaterial_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_biomaterial_biomaterial_name ON public.t_biomaterial USING btree (biomaterial_name);

--
-- Name: ix_t_biomaterial_campaign_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_biomaterial_campaign_id ON public.t_biomaterial USING btree (campaign_id);

--
-- Name: ix_t_biomaterial_ccname_container_id_ccid; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_biomaterial_ccname_container_id_ccid ON public.t_biomaterial USING btree (biomaterial_name, container_id, biomaterial_id);

--
-- Name: ix_t_biomaterial_container_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_biomaterial_container_id ON public.t_biomaterial USING btree (container_id);

--
-- Name: ix_t_biomaterial_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_biomaterial_created ON public.t_biomaterial USING btree (created);

--
-- Name: ix_t_biomaterial_id_name_container; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_biomaterial_id_name_container ON public.t_biomaterial USING btree (biomaterial_id, biomaterial_name, container_id);

--
-- Name: t_biomaterial fk_t_biomaterial_t_biomaterial_type_name; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_biomaterial
    ADD CONSTRAINT fk_t_biomaterial_t_biomaterial_type_name FOREIGN KEY (biomaterial_type) REFERENCES public.t_biomaterial_type_name(biomaterial_type_id);

--
-- Name: t_biomaterial fk_t_biomaterial_t_campaign; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_biomaterial
    ADD CONSTRAINT fk_t_biomaterial_t_campaign FOREIGN KEY (campaign_id) REFERENCES public.t_campaign(campaign_id);

--
-- Name: t_biomaterial fk_t_biomaterial_t_material_containers; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_biomaterial
    ADD CONSTRAINT fk_t_biomaterial_t_material_containers FOREIGN KEY (container_id) REFERENCES public.t_material_containers(container_id);

--
-- Name: t_biomaterial fk_t_biomaterial_t_users; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_biomaterial
    ADD CONSTRAINT fk_t_biomaterial_t_users FOREIGN KEY (pi_prn) REFERENCES public.t_users(username) ON UPDATE CASCADE;

--
-- Name: TABLE t_biomaterial; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_biomaterial TO readaccess;

