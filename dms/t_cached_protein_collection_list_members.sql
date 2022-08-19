--
-- Name: t_cached_protein_collection_list_members; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_protein_collection_list_members (
    protein_collection_list_id integer NOT NULL,
    protein_collection_name public.citext NOT NULL
);


ALTER TABLE public.t_cached_protein_collection_list_members OWNER TO d3l243;

--
-- Name: t_cached_protein_collection_list_members pk_t_cached_protein_collection_list_members; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_protein_collection_list_members
    ADD CONSTRAINT pk_t_cached_protein_collection_list_members PRIMARY KEY (protein_collection_list_id, protein_collection_name);

--
-- Name: TABLE t_cached_protein_collection_list_members; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_protein_collection_list_members TO readaccess;
GRANT SELECT ON TABLE public.t_cached_protein_collection_list_members TO writeaccess;

