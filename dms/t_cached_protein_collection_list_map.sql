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
-- Name: TABLE t_cached_protein_collection_list_map; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_cached_protein_collection_list_map TO readaccess;

