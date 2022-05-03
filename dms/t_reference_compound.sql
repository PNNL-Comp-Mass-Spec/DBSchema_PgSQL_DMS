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
    container_id integer NOT NULL,
    wellplate_name public.citext,
    well_number public.citext,
    contact_prn public.citext,
    supplier public.citext,
    product_id public.citext,
    purchase_date timestamp without time zone,
    purity public.citext,
    purchase_quantity public.citext,
    mass double precision,
    created timestamp without time zone NOT NULL,
    active smallint NOT NULL,
    id_name public.citext GENERATED ALWAYS AS (((((compound_id)::public.citext)::text || ':'::text) || (compound_name)::text)) STORED
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

--
-- Name: TABLE t_reference_compound; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_reference_compound TO readaccess;

