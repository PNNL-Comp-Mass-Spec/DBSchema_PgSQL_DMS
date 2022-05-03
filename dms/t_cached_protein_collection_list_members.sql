--
-- Name: t_cached_protein_collection_list_members; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_protein_collection_list_members (
    protein_collection_list_id integer NOT NULL,
    protein_collection_name public.citext NOT NULL
);


ALTER TABLE public.t_cached_protein_collection_list_members OWNER TO d3l243;

--
-- Name: t_cached_protein_collection_list_protein_collection_list_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_cached_protein_collection_list_map ALTER COLUMN protein_collection_list_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_cached_protein_collection_list_protein_collection_list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_cached_protein_collection_list_members pk_t_cached_protein_collection_list_members; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_protein_collection_list_members
    ADD CONSTRAINT pk_t_cached_protein_collection_list_members PRIMARY KEY (protein_collection_list_id, protein_collection_name);

--
-- Name: TABLE t_cached_protein_collection_list_members; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_protein_collection_list_members TO readaccess;

