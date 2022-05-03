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
    container_id integer NOT NULL,
    material_active public.citext NOT NULL,
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
    cell_line public.citext
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
-- Name: TABLE t_biomaterial; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_biomaterial TO readaccess;

