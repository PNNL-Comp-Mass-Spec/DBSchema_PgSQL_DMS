--
-- Name: t_cached_protein_collection_list_map; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_cached_protein_collection_list_map (
    protein_collection_list_id integer NOT NULL,
    protein_collection_list public.citext NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.t_cached_protein_collection_list_map OWNER TO d3l243;

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
-- Name: t_cached_protein_collection_list_map pk_t_cached_protein_collection_list_map; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_cached_protein_collection_list_map
    ADD CONSTRAINT pk_t_cached_protein_collection_list_map PRIMARY KEY (protein_collection_list_id);

--
-- Name: TABLE t_cached_protein_collection_list_map; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_protein_collection_list_map TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_cached_protein_collection_list_map TO writeaccess;

