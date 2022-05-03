--
-- Name: t_cached_protein_collection_list_map; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_protein_collection_list_map (
    protein_collection_list_id integer NOT NULL,
    protein_collection_list public.citext NOT NULL,
    created timestamp without time zone
);


ALTER TABLE public.t_cached_protein_collection_list_map OWNER TO d3l243;

--
-- Name: t_cached_protein_collection_list_map pk_t_cached_protein_collection_list_map; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_protein_collection_list_map
    ADD CONSTRAINT pk_t_cached_protein_collection_list_map PRIMARY KEY (protein_collection_list_id);

--
-- Name: TABLE t_cached_protein_collection_list_map; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_protein_collection_list_map TO readaccess;

