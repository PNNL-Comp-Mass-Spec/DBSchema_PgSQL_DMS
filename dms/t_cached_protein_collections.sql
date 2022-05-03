--
-- Name: t_cached_protein_collections; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_protein_collections (
    protein_collection_id integer NOT NULL,
    organism_id integer NOT NULL,
    name public.citext NOT NULL,
    description public.citext,
    state_name public.citext,
    entries integer,
    residues integer,
    type public.citext,
    file_size_bytes bigint,
    created timestamp without time zone NOT NULL,
    last_affected timestamp without time zone NOT NULL
);


ALTER TABLE public.t_cached_protein_collections OWNER TO d3l243;

--
-- Name: t_cached_protein_collections pk_t_cached_protein_collections; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_protein_collections
    ADD CONSTRAINT pk_t_cached_protein_collections PRIMARY KEY (protein_collection_id, organism_id);

--
-- Name: TABLE t_cached_protein_collections; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_protein_collections TO readaccess;

