--
-- Name: t_cached_protein_collection_list_members; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_protein_collection_list_members (
    protein_collection_list_id integer CONSTRAINT t_cached_protein_collectio_protein_collection_list_id_not_null1 NOT NULL,
    protein_collection_name public.citext CONSTRAINT t_cached_protein_collection_li_protein_collection_name_not_null NOT NULL
);


ALTER TABLE public.t_cached_protein_collection_list_members OWNER TO d3l243;

--
-- Name: t_cached_protein_collection_list_members pk_t_cached_protein_collection_list_members; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_protein_collection_list_members
    ADD CONSTRAINT pk_t_cached_protein_collection_list_members PRIMARY KEY (protein_collection_list_id, protein_collection_name);

ALTER TABLE public.t_cached_protein_collection_list_members CLUSTER ON pk_t_cached_protein_collection_list_members;

--
-- Name: TABLE t_cached_protein_collection_list_members; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_protein_collection_list_members TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_cached_protein_collection_list_members TO writeaccess;

